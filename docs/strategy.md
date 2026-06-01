# AdriSuite — Strategic Direction

*Captured June 2026. Companion to roadmap.md — this is the why behind the what.*

---

## The Core Goal

AdriSuite exists to make construction as it is today so easy, so fast, and so cheap — through the organizational intelligence it provides automatically — that the current process is unrecognizable by comparison.

The reference point: imagine a technology that eliminated plumbing entirely — a spatial cap on a fixture that instantly transported water to a central system. No pipe routing, no penetrations, no MEP-structural conflicts, no sequencing around wet walls. Construction would be fundamentally faster, simpler, and cheaper — not because the problem got easier, but because an interface absorbed all the complexity.

AdriSuite is that interface for the building process. Not a better set of tools for the same coordination effort. A system so organizationally tight that the coordination effort itself disappears.

---

## Why Four Tools Is Right

The four-tool structure is not fragmentation — it is a sequential walkthrough that mirrors how a project actually moves through phases.

Each tool is independently auditable by its domain expert. A contractor reviewing AdriSnap doesn't need to understand AdriCad to trust what they're looking at. A QS reviewing AdriPlan doesn't need to understand MEP. That independence is what builds trust with each party on their own terms — which is the whole product.

The toilet tap analogy applies not to the UI structure but to what happens *within* each tool. Each tab should absorb so much complexity automatically that the user is only making decisions, never coordinating. The tools stay separate. The coordination burden disappears inside them.

---

## Depth Is the Path

Coordination is only as meaningful as the accuracy of what's being coordinated.

If AdriBim has a generic pipe roughly in the right area, and AdriCad has approximate ceiling heights, the "coordination" between them isn't catching real conflicts — it's displaying two approximations next to each other. A contractor looks at it and immediately knows it isn't real.

But when AdriBim knows actual fixture specs, actual pipe diameters, actual riser locations — and AdriCad has architecturally accurate ceiling heights, proper stairwell geometry, real door swing clearances — the conflict detection earns trust. The handoff means something because each layer was built with enough fidelity that a domain expert would recognize it as their work.

**This is the development principle: go deep in one layer at a time until a real domain expert would trust it, then ensure the handoff to the next layer preserves that fidelity.**

- AdriCad: architectural accuracy — ceiling heights, stairwell geometry, layout flow, door clearances
- AdriBim: MEP accuracy — real fixture specs, pipe sizing, riser placement, system routing logic
- AdriPlan: cost and schedule accuracy — structures a QS would sign off on, labor division a PM would recognize
- AdriSnap: sequence accuracy — site operations a foreman would actually use

Depth first. Coordination second. That is the order.

---

## The Intelligence Layer Is What Makes Depth Automatic

The intelligence database is not a lookup table — it is what gives each tool enough domain knowledge to generate realistic content without requiring the user to specify every parameter from scratch.

Every verified cost ratio, every regulatory fingerprint, every quantity benchmark encodes a decision the architect would otherwise have to make manually. As the intelligence layer grows, each tool gets closer to generating accurate-enough content automatically. That is how the system absorbs coordination effort over time.

The intelligence layer is also the moat. Software gets copied. Accumulated building intelligence specific to a market — verified against real bids, real permits, real projects — does not.

---

## The Long Pipeline

```
AdriCad → AdriBim → AdriPlan → AdriSnap → [Helmet]
```

AdriSuite is source code. AdriSnap is the compiler. The Helmet (future) is the runtime.

The Helmet horizon matters now — not because it is close, but because it defines what AdriSnap needs to become. AdriSnap is not just a sequence tool; it is the layer that generates machine-readable assembly operations with approach vectors and tolerance envelopes. Building AdriSnap now as if the Helmet is two years away shapes which attributes get added and which shortcuts are worth avoiding.

---

## Practical and Real — Always

Most BIM software is designed by and for designers. The model looks correct in the software and means nothing on site. A pipe is a line. A wall is a surface. The connection between the model and how a worker actually picks up a fitting, approaches a junction, and makes it permanent — that gap is where projects fall apart, and where the 30–40% overhead lives.

AdriSuite is oriented toward end-state installation and life application. Every element should carry not just what it is, but how someone gets it there: in what order, with what clearance, with what tools, after what other things are already in place.

This is not an add-on philosophy — it is the foundation. The constructability layer in the schema (approach vector, tolerance spec, sequence position, temp works) exists for this reason. The intelligence layer is valuable not just for cost ratios and permit patterns, but for accumulated knowledge about what is hard to build, what fails in the field, and what contractors bid high on because they know it is a problem.

**The practical test for every element and feature:** does this mean something to the person on site? A model that looks right to a designer but tells a tradesperson nothing has not done its job.

---

## The Two Filters for Every Development Decision

**Filter 1 — Absorption:** Does this move us toward "the system absorbs this coordination task," or does it just make it easier to do manually? If the latter, it is a feature. If the former, it is infrastructure toward the goal.

**Filter 2 — Site reality:** Does this reflect how something is actually installed, sequenced, and maintained — or does it only reflect how it looks in a finished state? If a model element cannot answer the question "how does this get built," it is not yet complete.
