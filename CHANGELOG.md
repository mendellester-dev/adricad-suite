# Changelog

Version history for AdriSuite. Each entry corresponds to a git tag.
Prior to git, versions were tracked as numbered folders in BCP/1–50.

---

## v50 — 2026-05-31

Initial git baseline. Migrated from BCP/50 folder system.

### Tools at this version
- **AdriCad** — Design Studio, full 3D geometry definition
- **AdriBim** — Predesign MEP + 3D (v8)
- **AdriPlan** — Project Controls with AdriBridge schedule sync to AdriSnap
- **AdriSnap** — Block Assembly with construction sequence

### Inter-tool data bridge
- `AdriBridge` (BroadcastChannel + `adri:platform` localStorage)
- AdriPlan → AdriSnap via `adri:snap:schedule` localStorage key + `adriSync` URL param (BASE64)

### Known state
- Data layer is localStorage + JS objects passed between tools
- No Supabase backend yet — all state is client-side
- QTO (quantity takeoff) verification depth still being built

---

<!-- Add new entries above this line, newest first -->
<!-- Format: ## v51 — YYYY-MM-DD -->
