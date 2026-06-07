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

---

## The Assembly Detail Layer

Once routing paths are determined, each path must be resolved into a complete assembly — not just pipe centerlines or duct centrelines, but every component required to make the installation real and buildable. This is the layer that connects the routing map to site installation. A tradesperson should be able to read an Adri output and know exactly what components to order, where each one goes, how it connects to the next, and what has to be in place first.

**The core principle:** every routing path is an ordered sequence of components, each with geometry, clearance requirements, connection type, and installation sequence constraints. The routing engine must account for fitting geometry as part of the route — a 90° elbow on a 6" duct takes roughly 9" of radius to execute; that space must exist in the zone graph before the turn is placed.

---

### Sizing Transition Logic

Each discipline has a direction in which sizing changes along the routing tree. Adri must propagate sizing changes and place the correct transition fittings automatically.

| Discipline | Direction | Rule |
|-----------|-----------|------|
| DWV (sanitary drain) | Gets larger downstream toward stack | Aggregated fixture unit load determines pipe size at each segment; wye or tee-wye at each junction |
| Plumbing supply | Gets smaller away from main | Branch tee + reducer at each split; size driven by fixture unit demand remaining downstream |
| Sprinkler | Gets smaller as branch serves fewer heads | Reducing coupling or reducing tee at each step down; NFPA 13 pipe schedule governs |
| HVAC duct | Gets smaller at each branch takeoff | Reducing transition fitting at each split; CFM demand drives each segment size |
| Electrical conduit | Fixed per circuit, plus fill capacity | New conduit run starts where fill capacity is reached; junction box required at splice |

---

### Plumbing — Sanitary Drainage (DWV)

The assembly components required along every DWV routing path, in addition to the pipe itself:

**At every fixture connection:**
- P-trap (integral or field-installed depending on fixture type)
- Trap arm connecting P-trap to drain branch — minimum 1/4" per foot slope toward stack
- Cleanout access where trap arm exceeds 5ft or changes direction

**At every branch junction:**
- Wye fitting (not sanitary tee on horizontal lines — flow dynamics require wye geometry)
- Reducing fitting where branch meets a larger-diameter run

**At every change in direction on horizontal runs:**
- Two 45° fittings in sequence (not a single 90°) to maintain flow velocity
- Cleanout at each aggregate direction change if horizontal run exceeds 50ft total

**Vent connections:**
- Re-vent or wet vent from each fixture trap arm to vent stack
- Air admittance valve where individual branch venting is impractical (code-jurisdiction-dependent)
- Vent stack continuous to roof termination — minimum 6" above roof, 10ft from any air intake

**At stack base:**
- Sanitary combination Y with 1/8 bend — not a standard tee; this fitting redirects the vertical stack flow to horizontal
- Cleanout at stack base (required by code)

**Slope annotation on every horizontal segment** — slope in mm/m or inches/foot must be carried on every segment and verified as achievable given the vertical distance available between fixture outlet elevation and stack connection elevation.

---

### Plumbing — Pressurized Supply (Hot and Cold)

**At building entry / riser base:**
- Pressure reducing valve (PRV) if incoming pressure exceeds 80 psi
- Main shutoff valve (ball valve, full bore)
- Backflow preventer where required by jurisdiction
- Pressure gauge downstream of PRV

**At every branch junction:**
- Reducing tee matching main and branch diameters
- Branch isolation ball valve — allows individual branch isolation without shutting down the floor

**At every fixture connection:**
- Angle stop or stop valve at each fixture supply (hot and cold separately)
- Flexible supply lines from stop valve to fixture
- On hot water lines: expansion tank at water heater if closed system (PRV creates closed system)

**On hot water distribution:**
- Hot water recirculation return line (separate pipe, smaller diameter) to prevent cold-water wait at fixtures — runs parallel to supply back to water heater
- Check valve on recirculation return to prevent reverse flow
- Recirculation pump at water heater (timed or demand-activated)

**Isolation and access:**
- Shutoff valve at each floor riser takeoff
- Union fittings at water heater connections (allows equipment replacement without cutting pipe)
- Vacuum breakers at hose bibs and irrigation connections

---

### Sprinkler

**At every sprinkler head:**
- Head selected by type: pendant (most common — drops below pipe), upright (points up, used in exposed structure), sidewall (projects from wall, used where ceiling routing is obstructed)
- Escutcheon plate concealing rough ceiling opening
- On flexible drops: listed flexible sprinkler hose assembly (allows head repositioning without rerouting branch line)
- On seismic zones: flexible drop required within 12" of head

**At every branch line:**
- Branch line runs perpendicular to cross main
- Arm-over fitting where branch line meets cross main
- Branch line sized per NFPA 13 pipe schedule (number of heads remaining on that branch determines diameter)
- End-of-line test/drain valve (inspector's test connection — simulates single head flow for alarm testing)

**At cross main:**
- Reducing tee or cross fitting at each branch line takeoff
- Cross main sized cumulatively from end to riser — largest at riser connection
- End of main drain valve at low point

**At riser (per floor zone):**
- Floor control station assembly: alarm check valve + water motor alarm or pressure switch + pressure gauge on each side + inspector's test + main drain valve
- Riser check valve (prevents backflow between zones)
- Tamper switch on control valve (sends signal to fire alarm panel if valve is closed)

**Penetrations through rated assemblies:**
- Listed fire-rated sleeve at every wall and floor penetration
- Escutcheon ring on exposed side
- Seismic bracing at intervals per NFPA 13 (lateral and longitudinal, typically every 40ft and 80ft respectively)

---

### HVAC

**At every duct size transition:**
- Reducing transition fitting (flat-top reducer for ceiling-mounted runs to maintain consistent ceiling elevation; symmetric reducer for exposed runs)
- Balancing damper at each branch takeoff — allows airflow adjustment during commissioning

**At every 90° turn:**
- Radius elbow preferred (minimum bend radius = 1.5× duct width)
- Square elbow with turning vanes where space prevents radius elbow — turning vanes are required, not optional, to maintain pressure
- Fitting geometry must be solved as part of the route: a 24"×12" duct requires a minimum 24" turning radius — this space must be verified in the zone graph before the turn is placed

**At every fire-rated wall/floor penetration:**
- Listed fire/smoke damper (combination damper where both fire and smoke control required)
- Access door immediately adjacent to damper — required by code for testing and inspection, typically 12"×12" minimum
- Damper must be accessible from finished space — this drives where dampers can and cannot be placed

**At supply terminations:**
- Diffuser or register box (size and type driven by CFM per space and throw requirement)
- Flexible duct connector (6"–12" of flexible duct between rigid duct and diffuser box) — prevents vibration transmission and allows minor positional adjustment

**At equipment connections:**
- *VRF indoor unit:* refrigerant liquid line + suction line (line set sized per manufacturer for distance and elevation change), condensate drain with trap and slope to collection point, power supply disconnect within sight of unit, flexible electrical whip
- *VRF outdoor unit:* refrigerant line set from indoor units, power disconnect within 50ft and within sight, vibration isolation pads under unit, minimum clearances on all sides per manufacturer (typically 12"–24" sides, 36" service access face), condensate drain if heat pump reversing cycle
- *ERV / AHU:* ductwork connection with flexible connector, outdoor air intake with damper and screen, exhaust air outlet with damper, condensate drain with P-trap (trap depth = 1" per inch of static pressure), filter access door, power disconnect

**Condensate drainage:**
- Condensate lines slope minimum 1/8" per foot to drain
- P-trap required on every condensate drain line before connection to drain system (prevents sewer gas ingress)
- Condensate pump where gravity drain is impossible (common in ceiling-mounted units)
- Clean-out access at condensate manifold

---

### Electrical

**At every conduit run:**
- Pull box at every point where total bends in a conduit run exceed 360° — prevents wire damage during pull
- Junction box at every wire splice — no in-wall splices outside of a listed enclosure
- Conduit fill verified at every segment (NEC Table C): adding a circuit to an existing conduit requires checking whether fill capacity allows it

**At panel connections:**
- Circuit breaker sized per wire ampacity and load (not just load — breaker must protect the wire, not the device)
- Panel schedule completed for every panel: circuit number, load description, breaker size, wire size, phase assignment
- Neutral and ground bars separated in service entrance and main panels (combined in subpanels only where permitted)
- Feeder conductors sized for voltage drop as well as ampacity — long feeder runs in tall buildings require upsizing to keep drop under 3%

**Required devices by location:**
- GFCI protection at all wet locations (bathrooms, kitchens within 6ft of sink, laundry, outdoor, rooftop, mechanical rooms)
- AFCI protection at all bedroom circuits and in jurisdictions requiring whole-dwelling AFCI
- Tamper-resistant receptacles in residential units (required by NEC in all residential since 2008)

**At equipment connections:**
- Dedicated circuit for every large appliance (refrigerator, dishwasher, washing machine, microwave)
- Equipment disconnect within sight and within 50ft of motor-driven equipment (HVAC units, pumps, elevators)
- Disconnect must be lockable in the open position
- Flexible conduit or listed flexible cable ("whip") at final connection to equipment — prevents vibration transmission and allows equipment movement for service

**Grounding:**
- Grounding electrode system at service entrance (ground rod, building steel, water pipe — all bonded)
- Equipment grounding conductor in every conduit run with circuit conductors
- Bonding jumper at every metal water pipe, gas pipe, and structural steel within reach of electrical equipment

---

### Assembly Geometry in the Routing Engine

The routing engine must carry fitting geometry as real 3D volumes, not just pipe centerline offsets. The minimum clearances Adri must enforce:

| Component | Clearance Required |
|-----------|-------------------|
| 90° duct elbow (radius) | 1.5× duct width minimum radius |
| 90° duct elbow (square with vanes) | Duct width + 6" each direction |
| Pipe elbow (1.5D radius) | 1.5× nominal pipe diameter |
| Sprinkler head (pendant) | 18" below ceiling minimum, 4" from side wall |
| VRF outdoor unit service access | 36" on service face, 12" on all other sides |
| Electrical panel working space | 36" deep × panel width × 6.5ft tall (NEC 110.26) |
| Floor control station (sprinkler) | 36" in front, 18" each side |
| Fire/smoke damper | Access door within 12" on accessible side |
| Condensate pump | Accessible from finished ceiling or service panel |

These clearances must be represented in the zone graph as reservations — when a fitting is placed, its clearance volume is marked as occupied so no other system can route through it.

---

---

## The Component Library

The assembly detail layer describes what components are needed and where. The component library is the data structure that makes those components computable — queryable by the routing engine, placeable in the zone graph, and exportable to a coordination drawing or installation instruction set.

Without the library, the assembly layer is documentation. With it, Adri can place a P-trap, know its dimensions, know what connects to it on each port, know what has to be installed before it can go in, and know what clearance it needs around it. The library is what makes the difference between a report and a buildable instruction.

### Library Entry Structure

Every component in the library is a typed object with the following fields:

```json
{
  "id": "DWV-PTRAP-2IN",
  "discipline": "plumbing_dwv",
  "category": "trap",
  "label": "P-Trap, 2\" DWV",
  "description": "Standard P-trap for 2\" sanitary drain branch. Required at every fixture outlet.",

  "geometry": {
    "body_envelope_mm": { "x": 200, "y": 150, "z": 120 },
    "installation_envelope_mm": { "x": 300, "y": 300, "z": 200 },
    "ports": [
      { "id": "inlet",  "type": "dwv_socket",  "diameter_mm": 50, "direction": [0, 0, 1],  "offset_mm": [0, 75, 0]  },
      { "id": "outlet", "type": "dwv_spigot",  "diameter_mm": 50, "direction": [1, 0, 0],  "offset_mm": [100, 0, 0] }
    ]
  },

  "connections": {
    "inlet":  ["DWV-FIXTURE-OUTLET", "DWV-TRAPARM"],
    "outlet": ["DWV-TRAPARM", "DWV-WYE-INLET"]
  },

  "sizing_rule": {
    "trigger": "fixture_type",
    "lookup": "IPC_TABLE_709.1",
    "minimum_diameter_mm": 38,
    "default_diameter_mm": 50
  },

  "placement_rules": [
    { "rule": "slope_required", "direction": "outlet_to_stack", "min_slope_mm_per_m": 20.8, "code_ref": "IPC 2021 §704.1" },
    { "rule": "max_trap_arm_length_m", "value": 1.5, "code_ref": "IPC 2021 §909.1" },
    { "rule": "accessible_for_cleaning", "note": "Must be reachable without removing fixed structure" }
  ],

  "sequence": {
    "must_precede": ["DWV-BRANCH-PIPE", "FLOOR-FINISH"],
    "must_follow":  ["ROUGH-FRAMING", "DWV-ROUGH-IN"]
  },

  "clearances": {
    "service_access_mm": { "front": 300, "sides": 150, "below": 200 }
  },

  "code_refs": ["IPC 2021 §1002", "IPC 2021 §709"],
  "flexibility": "hard",
  "status": "PROVEN",
  "proven_contexts": ["residential_multistorey", "commercial_office"]
}
```

Every field has a purpose the routing engine can act on:
- `geometry.ports` tell the engine where pipes connect and in what direction — so it can chain components together into a valid assembly
- `connections` tell the engine what can legally connect to each port — so it can validate the assembly
- `sizing_rule` tells the engine how to select the right variant of this component based on the load it carries
- `placement_rules` are the code constraints encoded as machine-readable rules — slope requirements, max run lengths, access requirements
- `sequence` is the constructability layer — what must be in place before this component can go in, and what this component blocks until it's in
- `clearances` feed directly into the zone graph as space reservations

### Library Organisation

The library is structured in four top-level disciplines, each with categories and sub-categories:

```
library/
├── plumbing_dwv/
│   ├── traps/           P-trap, drum trap, floor drain trap
│   ├── fittings/        Wye, san-tee, combo, cleanout, reducer, coupling
│   ├── stacks/          Stack base, stack extension, stack termination
│   └── venting/         Re-vent tee, air admittance valve, vent termination
│
├── plumbing_supply/
│   ├── valves/          Ball valve, gate valve, angle stop, PRV, check valve, backflow preventer
│   ├── fittings/        Tee, elbow, reducer, union, coupling
│   ├── equipment/       Expansion tank, water hammer arrestor, recirculation pump
│   └── fixtures/        (stub connection geometry only — fixture library is separate)
│
├── hvac/
│   ├── duct_fittings/   Reducer, elbow (radius + square-with-vanes), tee, wye, cap
│   ├── terminal/        Diffuser, grille, register, VAV box, fan coil unit stub
│   ├── dampers/         Fire damper, smoke damper, combination, balancing, motorised
│   ├── equipment/       AHU stub, VRF indoor head, VRF outdoor unit, ERV, condensate pump
│   └── accessories/     Flexible connector, access door, test port, insulation spec
│
├── sprinkler/
│   ├── heads/           Pendant, upright, sidewall, extended coverage, concealed
│   ├── fittings/        Tee, cross, elbow, coupling, reducer, drop nipple, flexible drop
│   ├── control/         Floor control station assembly, inspector's test, riser check valve
│   └── support/         Seismic brace (lateral + longitudinal), hanger
│
└── electrical/
    ├── conduit/         EMT, rigid, flexible — with bend radii and fill tables
    ├── boxes/           Junction box, pull box, outlet box (by cubic inch capacity)
    ├── devices/         Receptacle, switch, GFCI, AFCI, tamper-resistant
    ├── panelboard/      Panel assembly (with breaker schedule schema)
    ├── equipment/       Disconnect, motor starter, VFD stub
    └── grounding/       Ground rod, bonding jumper, grounding electrode conductor
```

### Variant Handling

Most components exist in multiple sizes. A ball valve exists in 3/4", 1", 1.25", 1.5", 2", 2.5", 3", and 4" variants. Rather than one library entry per size, each entry carries a size series and a sizing rule that tells the routing engine which variant to select based on the pipe diameter it's connecting to:

```json
"size_series": [20, 25, 32, 40, 50, 65, 80, 100],
"sizing_rule": { "match": "upstream_pipe_diameter", "rounding": "up_to_nearest" }
```

The routing engine selects the variant at placement time, not at library authoring time. This keeps the library compact and the variant logic in one place.

### Required vs. Optional vs. Jurisdiction-Variable Components

Not every component is required in every context. The library carries a placement condition for each component:

- **Required** — code mandates this component in this location (e.g., P-trap at every fixture, fire damper at every rated penetration). Adri places these automatically.
- **Default** — industry standard in this context but code allows exceptions (e.g., balancing damper at every HVAC branch). Adri places these with a flag that the engineer can remove with justification.
- **Jurisdiction-variable** — required in some codes but not others (e.g., AFCI protection scope, air admittance valve acceptance). Adri places or omits based on the jurisdiction selected for the project, and flags all jurisdiction-variable decisions in the output.
- **Engineer-specified** — no automatic placement; engineer places manually (e.g., specific valve types at equipment, isolation strategy choices).

### The Library as a Living Asset

The component library is not a static catalogue — it is one of the compound assets that grows with use. When an engineer overrides a component selection (different valve type, different fitting geometry, different sizing), that override is logged against the context: building type, jurisdiction, system, reason. Over time the library learns which components are actually specified for which contexts, and the default selections improve.

When a new jurisdiction is added to the system, the jurisdiction-variable components for that jurisdiction are flagged as unverified until a project in that jurisdiction has been run and reviewed. Verified jurisdiction variants are marked as PROVEN in that context.

### Connection to the Zone Graph

When the routing engine places a component from the library, it does three things simultaneously:

1. **Reserves the body envelope** in the zone graph — the physical space the component occupies
2. **Reserves the installation envelope** in the zone graph — the clearance needed to install it
3. **Reserves the service access clearance** — the permanent clear space needed for future maintenance

All three are distinct. A VRF outdoor unit's body is 900×350×700mm. Its installation envelope is larger — equipment needs to be lifted and positioned. Its service clearance is 36" on the service face permanently. The zone graph must carry all three, or a route that looks valid on screen will fail on site.

---

## What Adri Is Building

A system that derives intelligent conclusions and implementation mapping plans from models that are completely geometrically modeled but missing semantic data. The output is not a compliance report — it is a complete annotated building map with routed systems resolved to the assembly level: every pipe sized, every fitting placed, every valve located, every clearance verified. The output tells a tradesperson what to order, where it goes, how it connects, and what has to be in place first.

The intelligence is in the inference. The moat is in what the inference gets better at over time.
