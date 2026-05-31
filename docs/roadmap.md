# AdriSuite — Roadmap

Active development priorities. Update this file as things get done or reprioritized.
For completed work see [CHANGELOG.md](../CHANGELOG.md).

---

## Now — Foundation

- [ ] **Schema integrity** — Define core project schema in Supabase: spaces, elements, systems, connections. This is the foundation everything else rests on. *(See schema/core-project.sql)*
- [ ] **Supabase project setup** — Create project, connect to tools via JS client
- [ ] **Replace localStorage bridge** — Move `adri:platform` state into Supabase, keep BroadcastChannel for real-time sync between open tabs

## Next — Depth

- [ ] **QTO verification** — Make quantity takeoffs accurate enough a real contractor would sign off on one typology in one municipality. One verified proof point > broad coverage.
- [ ] **Constructability attribute layer** — Add approach geometry, tolerance spec, sequence position to every AdriSuite element type
- [ ] **Confidence signal** — Surface model completeness as a signal alongside quantities. A CMU count with 60% model completeness reads differently than one at 95%.

## Later — AdriSnap as Compiler

- [ ] **Staged exploded view** — Generate explosion paths from finalized AdriSuite model
- [ ] **Reverse paths** — Explosion direction reversed = approach vectors for every element
- [ ] **Tolerance envelopes** — Add progressive tightening along each approach path
- [ ] **Sequence output** — Export construction sequence with dependencies

## Long-term — The Helmet

- [ ] **Problem Library** — Catalog specific construction operations with current costs, failure modes, levitation parameter requirements
- [ ] **Workflow maps** — 3–5 key operations assuming variable gravity parameter
- [ ] **Parameter boundaries** — Minimum payload, positional accuracy, power consumption, cycle time
- [ ] **University lab relationships** — Technion / TAU acoustic metamaterials and phononic crystals groups
- [ ] **Helmet spec v0.1** — Sensory layer, translation layer, feedback layer definition

---

## Principles

- **Narrow and deep before wide** — Pick one typology, one municipality. Prove it there first.
- **Log everything from real use** — Every user change + system response is training data. Cannot be reconstructed retroactively.
- **Keep logic clean, not clever** — A system where you can see why it made a decision is one you can fix.
