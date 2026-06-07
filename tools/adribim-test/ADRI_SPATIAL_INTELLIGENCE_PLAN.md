# Adri — Spatial Intelligence Plan
## From Geometry-Only Models to Intelligent MEP Coordination

*Authored June 2026. This document defines the foundational approach for Adri's spatial reasoning engine — the layer that turns raw IFC geometry into an actionable building map that MEP routing can operate on.*

---

## The Core Problem

Most IFC models encountered in practice are geometry-only: walls, slabs, beams, fixtures — but no semantic space information. No `IfcSpace` entities, no room classifications, no zone designations, no structural type assignments. This is not an edge case; it is the norm for mid-market projects.

A compliance checker can operate on geometry-only models by applying code rules to what's explicitly present. A routing engine cannot. Routing requires understanding the building as a collection of navigable and non-navigable space — what can run where, through what, at what cost. That understanding has to be derived from the geometry rather than read from the model.

**Adri's spatial intelligence layer is the system that performs this derivation.** It takes one or two geometry-only IFC models and produces an annotated building map — classified spaces, navigable zones, structural barriers, void depths — that the MEP routing engine can operate on. The map is the foundation. Everything else is built on top of it.

The goal: intelligent conclusions and implementation mapping plans from models that are completely geometrically modeled but missing semantic data.

---

## Two-Model Input: Architectural + Structural

Adri is designed to accept two IFC models for the same building:

- **Architectural model** — walls, partitions, finishes, fixtures, doors, windows
- **Structural model** — load-bearing walls, columns, beams, slabs with thickness, slab openings

The two-model approach directly solves the hardest classification problem: distinguishing structural elements from partitions. Without the structural model, this requires unreliable heuristics. With it, it becomes a geometric comparison problem — and a tractable one.

### Alignment

The two models may not share the same coordinate origin, especially if exported from different authoring tools or at different times.

**Step 1 — Check for shared base point.** Compare the bounding boxes of both models. If they overlap cleanly within a small tolerance (~100mm), assume the coordinate systems are aligned and proceed.

**Step 2 — Column grid matching.** If bounding boxes don't align, find structural columns in the structural model — they are geometrically distinctive (small plan footprint, full floor height) and almost always present in both models. Compute the translation vector that brings the column positions into agreement. Return a transformation matrix and a confidence score based on match quality.

**Step 3 — User confirmation fallback.** If automatic alignment confidence is below threshold, surface the finding to the user: "I found the structural model but the coordinate origins don't match. I believe these are the same building — can you confirm before I proceed?" Do not proceed with low-confidence alignment silently.

### Coincidence Detection

Once aligned, compare architectural walls against structural elements with a spatial tolerance band of ±50mm. This tolerance accounts for the fact that a structural concrete wall and an architectural finished wall are modeled at slightly different faces (offset by the finish layer thickness, typically 20–50mm).

- Architectural wall with structural element within tolerance → **load-bearing**
- Architectural wall with no structural counterpart → **partition**
- Structural column within an architectural wall → **column in wall**
- Structural slab opening → **intended shaft or penetration zone**

When only the architectural model is available, Adri falls back to thickness-based heuristics (wall over 200mm → likely structural, on building perimeter → envelope) but flags all structural classifications as inferred rather than confirmed.

---

## The Five-Layer Approach

### Layer 1 — Space Boundary Detection

Derive the enclosed polygons per floor from wall geometry. The output is not elements — it is the negative space defined by where the walls are.

For each bounded polygon, compute:
- Area (m²)
- Aspect ratio (long side / short side)
- Perimeter
- Number of door openings (connections to adjacent spaces)
- Adjacency list (which other spaces share a wall)
- Centroid coordinates

**Fallback for open-plan floors:** When no enclosed polygon is detected — large open-plan floors, reception areas, open kitchens — the system should not fail silently. Assume the floor plate minus structural elements is one navigable zone and flag it explicitly for review. Attempting to detect furniture-defined zones or functional boundaries within open plans is beyond the scope of geometry inference and should be escalated to user annotation.

### Layer 2 — Semantic Classification by Inference

Classify each bounded space using three types of evidence in combination. No single evidence type is authoritative — all three are scored and combined.

**Fixture evidence** (highest weight for wet/service rooms):
- WC + basin → wet room, high confidence
- Stair element → circulation core
- Equipment elements → mechanical/service room
- No fixtures + small area → shaft, cupboard, or structural core (ambiguous — see gap handling)

**Geometry evidence**:
- Aspect ratio > 4:1 + multiple door connections → corridor, high confidence
- Area < 2.0m² → shaft, cupboard, or WC (ambiguous without fixtures)
- Area > 50m² with no internal subdivisions → open-plan zone
- Roughly square, large area, central position → lobby or common area

**Position evidence**:
- At stair core position → circulation
- Clustered adjacent to confirmed wet rooms → likely wet or service
- At building perimeter with windows → habitable room
- Interior position, no windows → service or circulation

Each classification is assigned a confidence score (0–1). Classifications below 0.7 are flagged for engineer review rather than used silently.

**The building type inference** happens at this layer and must be resolved before system-level routing begins. Building type (residential, office, hotel, student residence, healthcare) determines which MEP rules apply across all four disciplines. If building type confidence is below threshold, Adri asks before proceeding — a wrong building type cascades errors through every system.

### Layer 3 — Void Space Derivation

MEP does not live in rooms. It lives in the spaces between finished surfaces and structural elements. Adri must derive the navigable void space for each zone.

**Plenum depth per zone:**
- Floor-to-floor height (from slab elevations in IFC) minus structural slab thickness minus finished floor buildup minus assumed ceiling zone depth
- If the structural model is present, slab thickness is read directly. If not, it is estimated from building type defaults (e.g., residential multi-storey: 200–250mm RC slab).
- Suspended ceiling presence is inferred: if floor-to-floor height exceeds the typical clear ceiling height for the building type by more than 300mm, a suspended ceiling is assumed. The depth difference minus finish tolerances is the plenum depth.

**Plenum depth variation within a floor** is a known failure mode. The system must compute plenum depth per zone, not per floor, because the same floor may have:
- Exposed structure in lobbies or common areas (plenum depth = 0 for MEP routing purposes)
- Suspended ceiling in apartments or offices
- Coffered or vaulted ceilings in feature spaces (ceiling height varies within the zone)

Where ceiling height variation is detected within a zone (from IFC ceiling or soffit elements), the system uses the minimum clearance as the conservative routing constraint and flags the zone as variable.

**Structural voids vs. navigable voids:**
A void between structural elements is not automatically navigable. Beams running through the ceiling zone reduce available depth. Post-tensioned slabs cannot be drilled. Transfer beams at mid-height of a plenum eliminate routing through that zone. These are read from the structural model where available; flagged as unknown where not.

**Wall cavity depth:**
Partition walls have cavities usable for small-diameter pipe and conduit. Structural walls do not. Cavity depth is estimated from wall thickness minus confirmed structural thickness (from the structural model comparison) or assumed by wall type.

### Layer 4 — The Zone Graph

Once spaces are classified and void depths calculated, construct the navigable graph.

**Nodes:**
- Each classified space (room, corridor, open-plan zone, shaft, plenum zone)
- Each distinct plenum zone (treated as a separate node from the occupied space below it)
- Mechanical rooms, shafts, and the building exterior (connection to utility mains)

**Edges:**
Each wall or slab between two nodes is an edge with attributes:
- Element type (partition / structural / envelope / party wall)
- Fire rating (read from IFC property sets if present; inferred from element type and building type if not)
- Allowable penetration size (derived from element type and fire rating)
- Penetration cost (composite of: structural impact + fire stopping requirement + schedule time)
- Directionality: slabs have a gravity direction (top to bottom costs more for drainage than bottom to top)

**Vertical edges:**
Shafts identified from structural slab openings and confirmed as continuous through multiple floors are high-value routing paths — low cost for all systems that need vertical runs. The stair core is a known anchor; other shaft locations may be inferred or user-defined.

**Cost model summary:**
| Edge type | Penetration cost | Notes |
|-----------|-----------------|-------|
| Partition wall | Low | Freely cuttable |
| Structural masonry | High | Needs assessment |
| Structural concrete | Very high | Needs engineer sign-off |
| Envelope / party wall | Prohibited | No MEP penetration |
| Non-PT slab | Medium | Fire stopping required |
| PT slab | Prohibited | No drilling |
| Existing shaft | Free | Intended for risers |

### Layer 5 — MEP Routing on the Graph

With the zone graph established, MEP routing becomes a constrained path-finding problem. Each system has sources, destinations, and rules. Adri finds paths through the graph subject to those rules.

This layer is addressed in the separate routing plan. The zone graph from Layer 4 is the input; routed system geometry is the output.

**The gravity constraint for DWV is the special case.** Gravity drain lines must slope (minimum 1/4" per foot for lines under 3", 1/8" per foot for 3"–6"). This makes routing directional — paths through the zone graph are only valid if the path can maintain slope from fixture to stack without reversing direction. The slope constraint means the stack location is a gravity anchor around which all DWV routing must be solved, not just a destination node. This constraint is solved in 3D, not just in plan.

---

## Failure Modes and Gap Handling

These are the cases where a human would recognize function intuitively but the system will not — and where silent failures cause the most damage.

### Small Room Ambiguity
A 1.5–2.0m² enclosed space could be a WC, a cupboard, a shaft, a comms room, or a structural core. Geometry alone cannot reliably distinguish these. **Rule:** any space below 3.0m² with no fixture evidence and no shaft-opening evidence from the structural model gets classified as "unknown — requires annotation" and is excluded from routing until confirmed.

### Fixture-Free Wet Rooms
Laundry rooms with only drain stub-outs, commercial kitchens with only slab penetrations, wet rooms where appliances weren't modeled. **Rule:** check for floor drains, waterproof membrane elements, and tile finish elements as wet-room indicators independent of sanitary fixture presence. Also apply adjacency reasoning: a space adjacent to two confirmed wet rooms with a plumbing chase nearby is likely wet even without fixtures.

### Open-Plan Spaces
Space boundary detection from wall polygons fails on open-plan floors. **Rule:** when no bounded polygon is found for a floor area, create a single open-plan zone node covering the floor plate minus structure. Flag it for user annotation of functional zones before routing proceeds.

### Variable Plenum Depth
The system must not assume uniform plenum depth across a floor. Exposed structure zones (depth = 0), coffered zones (variable), and standard suspended ceiling zones must be distinguished. **Rule:** compute plenum depth per classified zone. Flag any zone where ceiling height variation exceeds 300mm within the zone as variable.

### The Skin Model Gap
When interior partitions are missing or simplified in the IFC, space boundary detection finds large open zones that are actually subdivided in the real building. **Rule:** when using area-estimated room boundaries (as in the current test file), all routing paths that would require penetrating inferred walls are flagged as uncertain. The system routes conservatively — treating uncertain walls as structural until confirmed otherwise.

### Structural Element as Routing Barrier
Transfer beams, outrigger structures, and post-tensioned slabs are present in the structural model but not flagged as routing barriers by default. **Rule:** any structural element with a horizontal span greater than 3m at mid-height of a ceiling void is treated as a routing barrier in that zone. PT slabs are flagged as no-drill from slab type properties if present, or from structural engineer annotation.

### Walls Without Structural Model
When only the architectural model is available, wall type classification falls back to heuristics. All heuristic structural classifications are marked as "inferred — unconfirmed" and carry a penetration cost premium (one tier higher than confirmed equivalent). The user is prompted to provide a structural model or confirm classifications manually before final routing output is generated.

---

## The Confidence Model

**The most dangerous failure mode is confident wrong classification — not wrong classification itself.**

Every classified element carries a confidence score. The confidence model governs what happens at each confidence tier:

| Confidence | Action |
|------------|--------|
| ≥ 0.85 | Proceed; note classification in output |
| 0.70 – 0.84 | Proceed with flag; surface to engineer for review |
| 0.50 – 0.69 | Hold and ask; do not route through this zone until confirmed |
| < 0.50 | Exclude from routing; mark as unknown on output map |

**Engineer corrections are training data.** When an engineer confirms or overrides a classification, that correction is logged against the building type, element geometry, and context. Over time this calibrates the inference model for specific building types and jurisdictions — and becomes the compound intelligence asset.

---

## Implementation Sequence

**Phase 1 — Dual-model alignment module**
Accepts two IFC files, returns a transformation matrix and confidence score. Column grid matching as primary method. Bounding box check as pre-screen. User confirmation fallback. Discrete and testable independently.

**Phase 2 — Space boundary detection**
Wall polygon extraction per floor. Fallback for open-plan zones. Area, aspect ratio, door count, adjacency computed for each bounded space. Output: spatial graph of spaces with geometric attributes only.

**Phase 3 — Semantic classification**
Fixture evidence + geometry evidence + position evidence combined with confidence scoring. Building type inference first (gates everything else). Small space and open-plan fallback rules. Output: classified space map with confidence scores and flagged unknowns.

**Phase 4 — Structural overlay**
Apply structural model comparison (if available) to confirm or refute heuristic structural classifications. Update edge costs in zone graph accordingly. Flag all heuristic classifications as inferred where no structural model is present.

**Phase 5 — Void space derivation**
Per-zone plenum depth calculation. Beam and column zone exclusions. PT slab identification. Output: each zone annotated with available routing volume per system type.

**Phase 6 — Zone graph construction**
Nodes, edges, costs as described above. Shaft nodes from structural openings. Vertical edge construction. Output: navigable graph ready for routing engine.

**Phase 7 — Routing engine**
Operates on the zone graph. System-specific rules per discipline. Gravity constraint solver for DWV. Cross-discipline coordination from start (not clash detection after). This phase is addressed in the routing plan.

---

## What Adri Is Building

A system that derives intelligent conclusions and implementation mapping plans from models that are completely geometrically modeled but missing semantic data. The output is not a compliance report — it is an annotated building map that tells an MEP engineer where systems can run, what they'll cost to install, and what decisions need to be made before routing can proceed.

The intelligence is in the inference. The moat is in what the inference gets better at over time.
