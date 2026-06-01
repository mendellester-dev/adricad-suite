# AdriSuite Design System Plan
## AdriCad + AdriBim — Depth, Cohesion, Realism

*Goal: Each tool generates content so accurate and domain-specific that a practicing architect or MEP engineer would recognize it as their own working method — and that a tradesperson on site would recognize as something they can actually build. The coordination between them earns trust because each layer was built at professional fidelity and oriented toward real installation, not just correct appearance.*

**The standing test for everything in this document:** does it mean something to the person on site? A model that satisfies a designer but tells a plumber or electrician nothing has not done its job.

---

## Part 1 — Shared Design Language (Foundation)

Before deepening either tool, the two tools need a unified visual and interaction foundation. Right now they are close but divergent — AdriCad uses warm paper tones and Syne as the dominant face, AdriBim uses a warmer amber accent and slightly different panel proportions. Small inconsistencies compound into "feels like two different products."

### 1.1 Shared CSS Token System

Extract a single `adri-tokens.css` (or a `<style>` block at the top of each file that is identical) defining:

**Color tokens**
- `--adri-bg` — base background (warm off-white, same across both)
- `--adri-ink`, `--adri-ink2` — primary and secondary text
- `--adri-muted`, `--adri-soft` — tertiary and placeholder text
- `--adri-line`, `--adri-line2` — border weights
- `--adri-field`, `--adri-field2` — input and panel fill
- `--adri-paper` — canvas / drawing surface
- `--adri-green`, `--adri-green2`, `--adri-gdk` — primary action color (currently split between tools)
- MEP system colors (defined once, used by both tools):
  - `--sys-water: #2868a8`
  - `--sys-waste: #7040a0`
  - `--sys-hvac: #2a8f88`
  - `--sys-power: #b06010`
  - `--sys-gas: #e04040`
  - `--sys-fire: #c03020`
  - `--sys-core: #b03228`

**Typography scale**
- `--font-display`: Instrument Serif — headings, brand moments
- `--font-ui`: Syne — labels, buttons, controls
- `--font-data`: DM Mono — measurements, coordinates, specs, data readouts

**Spacing and radius scale** — 4px base unit, consistent border-radius tiers (4px micro, 6px small, 8px card, 12px modal)

**Shadow scale** — two levels used consistently across both tools

### 1.2 Suite Bar

The suite bar is the one persistent element across all four tools. It should be pixel-identical. Currently AdriCad uses height 38px, AdriBim uses 36px. The nav link style differs slightly. Standardize to one spec and apply it to all four tools simultaneously.

### 1.3 Panel and Section Components

Both tools use a left panel with sections. The section header pattern (DM Mono, 9px, uppercase, letterSpacing .14em, bottom border) is nearly identical but has minor divergences. Define it once and apply consistently.

---

## Part 2 — AdriCad: Architectural Depth

### Current State

AdriCad generates 3D massing geometry by architectural style, with a 2D floor plan layer and circulation routing. The style selector has 30 city options. The geometry exists but lacks the specific architectural language that makes a professional recognize it as their workflow.

### 2.1 Floor Plan Accuracy

The 2D plan needs to operate at the fidelity level a schematic design drawing would require:

**Wall types** — distinguish between structural walls (200mm RC or CMU), partition walls (100mm), and external envelope walls (with insulation layer visible in plan). Each type drawn with correct line weight and hatch.

**Ceiling heights by space type** — not one height for the whole floor. Living areas: 2.8–3.2m. Bathrooms: 2.4m. Stairwell: full floor-to-floor clear. Mezzanines where relevant. These heights drive AdriBim's routing space calculations directly.

**Stairwell geometry** — proper stair geometry in plan: tread lines, up/down arrow, intermediate landing, handrail line. Currently a placeholder symbol. Should show correct tread count derived from floor height.

**Door and window schedule** — each opening tagged with a reference number. Width and height drawn to scale. Door swing shown. Threshold line at exterior. Window sill line in plan.

**Dimension strings** — primary room dimensions auto-generated and displayed in plan view. Overall building dimensions. Grid line references for structural bays.

**Room naming and area tags** — each space labeled with program name + calculated area in sqm. Font and position consistent with architectural drafting convention.

### 2.2 Section and Elevation Intelligence

AdriCad currently generates 3D massing but not section cuts or elevations. For architectural accuracy, the model should be able to produce:

**Cross-section** — a vertical cut through the building showing: floor slabs with thickness, wall construction, ceiling height variations floor to floor, stairwell clear height, roof construction type.

**Street elevation** — facade composition derived from the selected architectural style. Window proportions and rhythm, cornice line, parapet or roof profile, entrance treatment. These aren't decorative — they define the structural and envelope elements AdriBim routes through.

### 2.3 Structural Grid

Every building has a structural grid — column centres and beam spans — that determines where MEP can run. AdriCad should generate and display this grid:

- Structural bay dimensions (auto-suggested by typology, user-adjustable)
- Column positions shown in plan as filled circles at grid intersections
- Grid reference labels (A, B, C / 1, 2, 3)
- Beam spans derived from bay dimensions
- This grid exports to AdriBim so pipe and duct routing knows where it can and cannot go

### 2.4 Architectural Style Depth

The 30 city styles are a strong differentiator. Currently they drive the 3D massing geometry. They should also drive:

- **Typical floor-to-floor height** for that typology and period
- **Facade bay width** (e.g. Georgian: 4.5–5.5m; Haussmann: 6–7m)
- **Structural system** (load-bearing masonry vs. RC frame vs. steel frame — determines MEP routing rules)
- **Ceiling height profile** (piano nobile vs. uniform floors vs. loft)
- **Typical room program** for that typology (proportion of area assigned to living vs. service vs. circulation)

These parameters should populate the intelligence layer as verified data points, not just visual styles.

---

## Part 3 — AdriBim: MEP Depth

### Current State

AdriBim places MEP fixtures and routes systems in plan and 3D. The system color coding is good (water/waste/HVAC/power). The fixture panel has the right categories. The depth problem: fixtures are generic, routing follows basic geometry, and the 3D representation is schematic rather than recognizable to an engineer.

### 3.1 Fixture Specificity — Finished Dimensions and Installation Envelopes

Each fixture carries two sets of geometry: its finished footprint and its **installation envelope** — the space required to actually get it in place and connected. These are not the same thing, and the gap between them is where site problems live.

**Plumbing fixtures**
- WC: 480×360mm footprint, 300mm rough-in from wall, 100mm soil pipe at floor. Installation envelope: 600mm clear in front, 150mm each side, soil pipe sleeve must be cast before floor finish.
- Basin: 500×400mm, 32mm waste, 15mm hot+cold supply. Waste connection point and height marked. Bracket fixing positions shown.
- Bath: 1700×750mm, 50mm waste, 15mm hot+cold. Access panel location required — shown in plan as a dashed zone.
- Shower: 900×900mm or custom, 50mm waste, thermostatic valve position. Waterproofing zone shown around tray.
- Kitchen sink: 600×500mm double bowl, 40mm waste, 15mm hot+cold. Under-sink void dimensions for trap and isolation valve.

**MEP connection points shown in plan and 3D**
- Supply stub-out location on fixture
- Waste connection point and fall direction arrow
- Electrical connection point (socket, switch, hardwire)
- Isolation valve position for every water supply branch

**Sequence flags on fixtures**
- What must be in place before this fixture can be installed (e.g. floor screed, wall tile, structural frame)
- What must happen before this fixture is permanently connected (e.g. pressure test, inspection)

This makes the plan readable by a plumber or electrician — not just a designer. They can see what they're connecting, in what order, and what access they need.

### 3.2 Pipe Sizing and Routing Logic

Current routing connects fixtures with lines. Real routing follows hydraulic and physical rules:

**Pipe sizing**
- Cold water: 15mm branch, 22mm sub-main, 28mm main
- Hot water: same as cold, plus 22mm circulation return
- Waste: 32mm basin, 40mm bath/shower, 100mm WC, 110mm soil stack
- Gas: 15mm branch from 22mm main
- Sizes label on pipe segments in plan

**Routing hierarchy**
- Horizontal branches run at ceiling level or in screed
- Branches connect to a vertical stack (soil stack, water risers)
- Stack locations driven by structural core position from AdriCad
- Routing avoids structural elements using the structural grid from AdriCad

**Fall direction on waste pipes**
- 1:40 minimum fall shown as arrow on waste branch
- Visual warning when layout geometry makes fall impossible

### 3.3 HVAC Routing

Currently HVAC is represented as a single system type. It needs enough specificity that an engineer recognizes it:

**Duct types**
- Supply duct (rectangular or circular) — sized by airflow
- Return air duct — routed back to AHU
- Extract duct (bathrooms, kitchen) — to external, shorter path preferred
- Each shown in plan with width dimension and centreline

**Unit types**
- Split unit: indoor cassette location + outdoor unit stub
- Fan coil unit: ceiling-mounted, condensate drain route shown
- AHU: central plant location, supply/return duct distribution

**Coordination visibility**
- Duct shown at correct height band (above ceiling, in floor void, or exposed)
- Conflict highlight when duct crosses beam at insufficient clearance

### 3.4 Electrical Layout

Currently minimal. Should show:

**Circuit layout**
- Distribution board location (one per floor, or one per apartment)
- Circuit runs shown as thin lines from DB to zones
- Socket and switch positions shown as standard symbols
- Lighting circuit shown separately from power circuit

**Symbols**
- Standard electrical plan symbols (not just colored dots): double socket, single socket, switch, 2-way switch, spotlight, pendant, DB, isolator
- Each symbol sized correctly relative to plan scale

### 3.5 3D MEP Representation

The 3D view should show MEP at a fidelity level where a coordination meeting would use it:

**Pipe 3D**
- Pipes rendered as cylinders with correct diameter (not uniform lines)
- Fittings at junctions: elbows, tees, reducers — simple geometry but present
- System color coding maintained (water blue, waste purple, gas red, etc.)
- Valves shown at isolation points

**Duct 3D**
- Rectangular ducts rendered as box sections
- Transitions and bends shown
- Grille/diffuser symbol at supply and return terminations

**Clash visibility**
- Highlight in red where any MEP element intersects a structural element
- Highlight in yellow where clearance is less than minimum (300mm for maintenance access)

### 3.6 The Directed Graph View

AdriBim's architecture doc describes design chains running from experienced endpoint back to source. This should be visible in the tool, not just in the code:

**Chain view** (toggle in panel)
- Select any fixture (e.g. shower in bathroom 2)
- Tool highlights the full upstream chain: shower → supply branch → sub-main → riser → meter → incoming main
- Each node shows: pipe size, material, flow rate at that point
- Reverse direction shows: shower → waste branch → soil stack → drain → municipal connection

This is the visualization that makes AdriBim conceptually distinct from any other MEP tool. It shows the building as a system of experience chains, not as a collection of pipes.

---

## Part 4 — The Handoff Layer

### AdriCad → AdriBim Data Exports

The handoff is the proof that the two tools are one system. These are the specific data points AdriCad must export for AdriBim to consume:

- Floor plan geometry (room outlines, wall positions)
- Structural grid (column positions, bay dimensions)
- Ceiling heights per space
- Core position (wet wall / service core location)
- Window and door openings (for facade penetrations)
- Number of floors and floor-to-floor heights
- Typology and structural system type

### AdriBim Receives and Uses

- Uses structural grid to constrain routing paths
- Uses ceiling heights to determine routing space available
- Uses core position to locate vertical stacks
- Uses room program to pre-populate fixture sets (residential bathroom gets WC + basin + shower; kitchen gets sink + dishwasher)
- Uses typology to apply default MEP sizing ratios from intelligence layer

### Format

Currently via AdriBridge (BroadcastChannel + localStorage). The data structure for this handoff should be explicitly defined as a JSON schema — even before Supabase is connected — so the handoff is deterministic and testable.

---

## Part 5 — Execution Sequence

**Phase 1 — Shared tokens (1–2 days)**
Unify CSS tokens across both tools. Suite bar pixel-identical. No functional change, no regressions. Ships as v52.

**Phase 2 — AdriCad plan accuracy (1–2 weeks)**
Wall types, ceiling heights, stair geometry, dimension strings, room labels, structural grid. All visible in plan view. Grid exports to AdriBim handoff object. Ships as v53.

**Phase 3 — AdriBim fixture specificity + pipe sizing (1–2 weeks)**
Real fixture footprints and connection points. Pipe sizing labels. Routing hierarchy (branch → stack → main). Waste fall direction. Ships as v54.

**Phase 4 — AdriBim 3D MEP depth (1 week)**
Pipe cylinders with real diameters. Duct box sections. Clash highlighting. Ships as v55.

**Phase 5 — Handoff schema + directed graph view (1 week)**
Define explicit JSON handoff schema. AdriBim consumes structural grid from AdriCad. Chain view in AdriBim. Ships as v56.

**Phase 6 — Intelligence layer population**
One typology (residential_multi), one municipality (Tel Aviv), verified cost and MEP ratios from one real project. Feeds into pipe sizing defaults and fixture counts. Ongoing — not a single version.

---

## The Test

At the end of Phase 5, put the two tools in front of three people: one architect, one MEP engineer, and one site foreman or plumbing contractor — all from the Israeli market. Give them a brief: a 4-unit residential building in Tel Aviv. Ask the architect to set up the floor plan in AdriCad and pass it to AdriBim, then have the engineer route the MEP.

Then show the output to the contractor and ask one question: **could you build from this?**

Not "is it impressive." Not "does it look right." Could you actually go to site with this and know what to do?

If yes, the depth is real. If no, what they say tells you exactly what to build next — and it will almost certainly be something no BIM software has thought to include because BIM software has never asked a contractor that question.
