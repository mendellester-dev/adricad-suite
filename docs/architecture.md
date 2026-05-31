# AdriSuite — Architecture

## The Directed Graph Model

AdriSuite is not five tools sharing data. It is **one directed graph with five interfaces.**

Design, construction, and operation are one continuous directed graph, read at different resolutions and in different directions. The handoff problem — where cost overruns originate, where experiential failures occur — is eliminated when the graph is continuous.

| Tool | Direction | Domain |
|---|---|---|
| **AdriCad** | Spatial — where chains run, experiential outcome at endpoints | Design |
| **AdriBim** | Technical — system specs, component connections, performance | Coordination |
| **AdriPlan** | Economic — node costs, assembly sequence, dependencies | Cost + Schedule |
| **AdriSnap** | Operational — construction path, approach geometry, assembly sequence | Execution |
| **Helmet** *(future)* | Experiential — operator perception during execution | Site Reality |

The pipeline: `AdriSuite → AdriSnap → Helmet`

AdriSuite = source code. AdriSnap = compiler. Helmet = runtime environment.

---

## Three-Tool Architecture (Current)

The suite is split into independently auditable tools sharing one data foundation. This is a **trust architecture**, not a UX decision. A contractor evaluates pipe routing on its own terms. An accountant reviews the budget without understanding the architecture.

```
AdriCad  ──┐
           ├──► AdriBim  (primary revenue — MEP coordination drawings)
           └──► AdriPlan (financial layer — model-derived costs)
                    │
                    └──► AdriSnap (construction sequence compiler)
```

---

## Design as Reverse-Engineered Chains

Every building system is a directed graph from experienced endpoint back to source.

```
Felt condition → local device → distribution network → source system → site connection
```

Examples:
- Warm room → register → duct → air handler → gas line → meter → utility connection
- Clean body → showerhead → supply pipe → riser → meter → municipal main

Current MEP tools start at the source. Good engineers think from the experience node backward. **Nobody has built a tool that works this way.** This is what AdriBim should eventually become.

**Connection to AdriSnap:** The design chains define not just what the building is but how it has to be assembled. The assembly sequence is the design chain in reverse. AdriSnap is the design chains reversed and expressed as construction operations.

---

## AdriSnap — The Compiler Layer

A genuinely novel tool with no current market equivalent. For every element in the model, AdriSnap defines:

- **Snap point geometry** — connection interface as operational target, not just finished position
- **Approach vector** — optimal path for final meters of placement
- **Path envelope** — volumetric space the element occupies through entire movement
- **Tolerance cascade** — loose in transit, tightening progressively to snap point
- **Sequence dependencies** — what must be locked before this operation begins
- **Staging geometry** — where elements wait and the path to approach vector

**Geometric foundation:** A well-constructed exploded view implicitly encodes everything AdriSnap needs. Exploded view = disassembly from finished state. AdriSnap = assembly toward finished state. Same geometric information, opposite direction vectors.

Workflow:
1. Take finalized AdriSuite model
2. Generate staged exploded view
3. Define explosion paths as geometric vectors
4. Reverse those paths → approach vectors for every element
5. Add tolerance envelopes along each path
6. Sequence the reversals → construction sequence

---

## Current Data Layer (v50)

Currently informal — JavaScript objects passed between tools, localStorage as session-level bridge.

**Inter-tool bridge:**
- `AdriBridge` — BroadcastChannel + `adri:platform` localStorage key
- AdriPlan → AdriSnap via `adri:snap:schedule` localStorage key
- AdriSnap URL param: `adriSync` (BASE64 encoded schedule block)

**Target: Three-layer schema** *(see schema/)*

| Layer | Where | What |
|---|---|---|
| Core Project Schema | Supabase/PostgreSQL | Spaces, elements, systems, materials, costs, relationships |
| Application Schema | JavaScript | How tools represent data in UI — must mirror core schema |
| Intelligence Schema | Supabase (separate) | Building typologies, material costs, regulatory parameters, historical ratios |

---

## What AdriSuite Elements Need (Constructability Layer)

To enable AdriSnap, every element needs additional attributes:
- Connection approach geometry
- Temporary works requirements
- Sequence position
- Tolerance specification

This also improves AdriPlan cost models and AdriBim coordination.
