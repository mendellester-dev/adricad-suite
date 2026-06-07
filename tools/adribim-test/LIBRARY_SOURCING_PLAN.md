# Adri Component Library — Sourcing Plan
## Specific free sources, what to download, and what each gives the library

*This plan is concrete. Every source listed is free, publicly accessible, and gives specific data for the library. No open-ended suggestions.*

---

## What We Need From Each Source

For each component the library needs:
1. **Body dimensions** (mm) — how big is it physically
2. **Port positions and directions** — where pipes connect and at what angle
3. **Sizing rules** — which diameter variant to use based on load
4. **Placement rules** — code-mandated conditions (slope, access, spacing)

Different sources give different pieces. The plan below maps each source to what it provides.

---

## Source 1 — buildingSMART IFC Property Sets
**URL:** https://standards.buildingsmart.org/IFC/RELEASE/IFC4/ADD2_TC1/HTML/schema/ifchvacdomain/
**Format:** Free HTML documentation + downloadable EXPRESS schema
**License:** Creative Commons Attribution-NoDerivatives 4.0

**What it gives:** The canonical type definitions and property sets for every MEP component class in IFC. This is the schema Adri's library should mirror.

**Specific pages to read and extract:**
- `IfcValve` — https://standards.buildingsmart.org/IFC/RELEASE/IFC4/ADD2_TC1/HTML/schema/ifchvacdomain/lexical/ifcvalve.htm
  Gives: valve type enum (BALANCINGVALVE, CHECKVALVE, ISOLATING, PRESSUREREDUCING, etc.), standard property sets
- `IfcPipeFitting` — https://standards.buildingsmart.org/IFC/RELEASE/IFC4/ADD2/HTML/schema/ifchvacdomain/lexical/ifcpipefitting.htm
  Gives: fitting type enum (BEND, CONNECTOR, ENTRY, EXIT, JUNCTION, OBSTRUCTION, TRANSITION), property sets
- `IfcDuctFitting` — same domain, DuctFittingType enum (BEND, CONNECTOR, ENTRY, EXIT, JUNCTION, OBSTRUCTION, TRANSITION)
- Property Set Index — https://standards.buildingsmart.org/IFC/RELEASE/IFC2x3/TC1/HTML/psd/psd_index.htm
  Gives: full list of `Pset_*` property sets for all MEP types — use these as the baseline property fields for each library entry

**Action:** Read the IfcValve, IfcPipeFitting, IfcDuctFitting, IfcFlowTerminal type definitions. Use the property set fields as the baseline schema for Adri library entries. This takes one afternoon and defines the field structure for ~80% of the library entries.

---

## Source 2 — ICC Free Online Code Access (IPC 2021)
**URL:** https://codes.iccsafe.org/content/IPC2021P1
**Format:** Free browser-accessible HTML — no login required, no download needed
**License:** ICC free read access

**What it gives:** The actual sizing tables and placement rules that become `sizing_rule` and `placement_rules` fields in library entries.

**Specific chapters to extract:**

| Chapter | URL | What to extract |
|---------|-----|----------------|
| Chapter 7 — Sanitary Drainage | https://codes.iccsafe.org/content/IPC2021P1/chapter-7-sanitary-drainage | Table 709.1 (DFU values per fixture), Table 710.1 (pipe size by DFU load), §704.1 (slope rules), §708 (cleanout requirements) |
| Chapter 4 — Fixtures | https://codes.iccsafe.org/content/IPC2021P3/chapter-4-fixtures-faucets-and-fixture-fittings | Fixture minimum supply pressure, trap requirements per fixture type |
| Appendix E — Water Pipe Sizing | https://codes.iccsafe.org/content/IPC2021P1/appendix-e-sizing-of-water-piping-system | Sizing tables for pressure supply branches |
| Chapter 9 — Vents | Navigate from Chapter 7 index | Vent sizing table, air admittance valve conditions, max trap arm lengths |

**Action:** Open each chapter, find the relevant tables, and transcribe the key values directly into the library sizing rule JSON. Table 710.1 alone populates the sizing rules for the entire DWV branch pipe category.

---

## Source 3 — Charlotte Pipe DWV Dimensional Catalog
**URL:** https://www.charlottepipe.com/technical-hub/abs-pvc-dwv-dimensional-catalog
**Direct PDF:** https://www.charlottepipe.com/uploads/documents/technical/Plastic_Pipe_Fittings_DC-DWV609.pdf
**Format:** Free PDF download, no login
**License:** Free to use (manufacturer published)

**What it gives:** Exact body dimensions for every standard PVC/ABS DWV fitting from 1.5" through 6": P-traps, wye fittings, tees, elbows, reducers, couplings, cleanout adapters. Dimensions in both inches and mm. ASTM standard references.

**Specific data to extract:**
- P-trap dimensions by nominal pipe size (1.5", 2", 3", 4") → `geometry.body_envelope_mm`
- Wye fitting centerline dimensions → port offset calculations
- Elbow turn radius by diameter → bend radius for routing engine
- Reducer fitting lengths → transition fitting envelope

**Action:** Download the PDF. For each fitting category, read the dimensional table and create one library entry per fitting type (not per size — use the size series field). The dimensional catalog covers approximately 40 DWV fitting entries in one PDF.

---

## Source 4 — BIMobject (Free, Registration Required)
**URL:** https://www.bimobject.com/en/categories/plumbing
**Sprinkler:** https://www.bimobject.com/en/vikingcorp
**HVAC / VRF:** https://www.bimobject.com/en/mitsubishi-electric-us
**Format:** IFC, Revit RFA, SketchUp — free download after free account registration
**License:** Free for use in projects (manufacturer-published BIM objects)

**What it gives:** Real manufacturer geometry with accurate body dimensions for specific products. Particularly useful for equipment (VRF units, AHUs, floor control stations) where body geometry is complex and product-specific.

**Specific downloads:**

| Component | BIMobject URL | What to extract |
|-----------|--------------|----------------|
| Viking VK100 Pendant Head | https://www.bimobject.com/en/vikingcorp | Body envelope, pipe connection point, installation height |
| Mitsubishi VRF Outdoor Unit | https://www.bimobject.com/en/mitsubishi-electric-us/product/mitsubishielectric-046 | Body dimensions, service clearances (from product sheet), connection points |
| Mitsubishi VRF Indoor Concealed Ceiling | BIMobject Mitsubishi Electric page | Body depth (critical for plenum fit check), connection geometry |
| Pipe valves (various manufacturers) | https://www.bimobject.com/en/categories/plumbing | Ball valve body dimensions by nominal diameter |

**Process for each download:**
1. Download IFC version where available (preferred) — parse with ifcopenshell to extract bounding box and port positions
2. Where only Revit (.rfa) is available, note the product data sheet dimensions instead — these are in the product description on BIMobject

**Action:** Create a free BIMobject account. Download IFC files for the 8–10 most critical equipment items (VRF indoor/outdoor, sprinkler heads, major valve types). Parse with ifcopenshell to extract bounding boxes → populate `geometry.body_envelope_mm`.

---

## Source 5 — MEPcontent
**URL:** https://www.mepcontent.com/en/bim-files/
**Format:** Revit families, IFC — free download after free account registration
**Manufacturers available:** Mitsubishi Electric, Daikin, Grundfos, Flamco, and others

**What it gives:** Manufacturer-verified BIM objects with accurate geometry and product data, specifically curated for MEP engineers. Better metadata than BIMobject for MEP-specific properties.

**Specific items to source here:**
- Mitsubishi Electric full VRF product range (more complete than BIMobject for HVAC)
- Grundfos pumps (if circulating pumps are added to library)
- Pipe hangers and supports

**Action:** Use MEPcontent as the secondary HVAC equipment source after BIMobject. Focus on downloading IFC files for equipment where body geometry affects zone graph clearance reservations.

---

## Source 6 — Viking Sprinkler BIM Library
**URL:** https://www.vikingsprinkler.com/bim.php
**Direct library:** https://digital.vikingcorp.com/revit-family-library
**Format:** Revit RFA (primary), IFC available via BIMobject
**License:** Free

**What it gives:** Accurate sprinkler head geometry for pendant, upright, sidewall, and extended coverage heads — the four types Adri needs to place. Also valve trim geometry.

**Key products:**
- VK100 Series — standard pendant, most common residential/commercial head
- VK300 Series — concealed pendant (relevant for finished ceiling applications)
- Viking floor control valve assembly — the most complex sprinkler assembly; getting this geometry right matters for space reservation

**Action:** Download Revit families for the three head types (pendant, upright, sidewall). Extract body envelope from product data sheets (dimensions listed on Viking website). The exact head geometry matters less than the correct installation envelope (head must be within 12" of ceiling, 4" from side walls, etc.) — those come from NFPA 13.

---

## Source 7 — ICC / NFPA Code Tables (Sizing Rules)
**IPC 2021:** https://codes.iccsafe.org/content/IPC2021P1 — free, no login
**NFPA 13:** https://www.nfpa.org/product/nfpa-13-standard-for-the-installation-of-sprinkler-systems/p0013code — purchase required for full access, BUT the pipe schedule table (Table 22.4.2.1) is already encoded in our existing `mep_sprinkler.py` — extract directly from there
**NEC 2023:** Partially free at https://www.nfpa.org/codes-and-standards/all-codes-and-standards/free-access — ampacity tables (Tables 310.12, 310.16) available

**Extraction plan:**

| Table | Source | Data |
|-------|--------|------|
| IPC Table 709.1 — DFU per fixture | codes.iccsafe.org/content/IPC2021P1/chapter-7 | Sizing input for every plumbing fixture connection |
| IPC Table 710.1 — Drain pipe size by DFU | Same | Sizing rule for every DWV branch and stack |
| IPC §704.1 — Slope rules | Same | Placement rule for every horizontal DWV segment |
| NFPA 13 pipe schedule | Extract from mep_sprinkler.py PIPE_SCHEDULE array | Already encoded — translate to library format |
| NEC Table 310.16 — Wire ampacity | codes.iccsafe.org or NFPA free access | Sizing rule for electrical conduit/wire entries |
| SMACNA duct sizing tables | Not freely available — use ASHRAE handbook data encoded in mep_hvac.py | Extract from existing module |

**Action:** The single highest-value extraction is IPC Table 710.1 (drain pipe sizing by DFU). This one table populates the sizing rule for every DWV pipe segment in the library. Access it free at codes.iccsafe.org with no login.

---

## Source 8 — buildingSMART Sample IFC Files (Geometry Reference)
**URL:** https://github.com/buildingSMART/Sample-Test-Files
**Format:** IFC files, free, GitHub
**License:** Open

**What it gives:** Real IFC files with properly structured MEP elements — useful as reference for how IfcValve, IfcPipeFitting, IfcDuctFitting should be structured when Adri writes components back to IFC.

**Action:** Clone or browse the repo. Find MEP-related sample files. Use as reference for IFC write-back implementation, not for component dimensions.

---

## Extraction Sequence — What to Do First

The order below gives maximum library coverage for minimum effort:

**Day 1 — Schema and sizing rules (no downloads, pure reading)**
1. Read buildingSMART IfcValve, IfcPipeFitting, IfcDuctFitting property sets → define library entry schema
2. Open IPC 2021 Chapter 7 at codes.iccsafe.org → transcribe Table 709.1 (DFU) and Table 710.1 (drain sizing)
3. Extract PIPE_SCHEDULE from mep_sprinkler.py → translate to library sizing rule format
4. Extract duct sizing logic from mep_hvac.py → translate to library format

Result: sizing rules and placement rules for ~60 entries, no geometry yet

**Day 2 — DWV fitting geometry (one PDF)**
1. Download Charlotte Pipe DWV dimensional catalog PDF
2. Extract dimensions for: P-trap, wye, san-tee, reducer, coupling, cleanout adapter, elbow — in all standard diameters
3. Create library entries with real body envelope data

Result: ~40 DWV component entries with real geometry

**Day 3 — Equipment geometry (BIMobject + MEPcontent)**
1. Register free accounts on BIMobject and MEPcontent
2. Download IFC files for: VRF outdoor unit, VRF concealed indoor head, Viking pendant sprinkler head, Viking floor control station
3. Parse with ifcopenshell to extract bounding boxes
4. Check product data sheets for service clearances (listed on manufacturer pages)

Result: ~10 equipment entries with accurate geometry and clearances — the most critical ones for zone graph space reservation

**Day 4 — Wire up to routing engine**
1. Load library entries into the routing engine prototype
2. Verify that sizing rules resolve correctly against test building fixture counts
3. Verify that body/install/service clearances are reserved in zone graph

---

## What the Library Will NOT Have After This

These require purchase or manual authoring and are deferred:
- Full NFPA 13 hydraulic calculation parameters (pipe friction loss coefficients) — not freely available; use pipe schedule method for now
- SMACNA duct fitting pressure loss coefficients — not free; use simplified duct sizing for now
- Electrical conduit fill tables for unusual conduit types (RMC, IMC, FMC) — NEC free access covers EMT which is most common
- Non-US/non-IPC code variants — deferred until first non-US project

---

## Total Expected Library Coverage After Sourcing

| Discipline | Entries | Source |
|-----------|---------|--------|
| DWV fittings and traps | ~40 | Charlotte Pipe PDF + IPC tables |
| Supply plumbing fittings and valves | ~25 | buildingSMART property sets + IPC tables |
| Sprinkler heads and control assemblies | ~15 | Viking BIM + NFPA pipe schedule from existing module |
| HVAC duct fittings and dampers | ~30 | buildingSMART property sets + HVAC module |
| HVAC equipment stubs | ~10 | Mitsubishi BIMobject + MEPcontent |
| Electrical conduit, boxes, devices | ~25 | buildingSMART property sets + NEC free tables |
| **Total** | **~145 entries** | |

145 entries covers the components that appear on essentially every residential and small commercial project. It is enough to run the routing engine on the test building and produce a complete assembly-level output.
