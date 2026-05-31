# Schema

Three-layer data architecture for AdriSuite.

| File | Layer | Status |
|---|---|---|
| `core-project.sql` | Core project schema — Supabase/PostgreSQL | Skeleton — needs definition |
| `intelligence.json` | Intelligence schema — building typologies, cost ratios, regulatory params | Skeleton — needs population |

## The Three Layers

### Core Project Schema (core-project.sql)
Lives in Supabase/PostgreSQL. Defines what a project is at the data level — spaces, elements, systems, materials, costs, relationships. PostgreSQL enforces rules at the database level. The authoritative source of truth all three tools read from and write to.

### Application Schema
Lives in JavaScript within each tool. How tools represent data in the UI. Must faithfully reflect the core schema — not an independent invention that drifts from the source of truth.

### Intelligence Schema (intelligence.json)
Lives in Supabase, separate from project data. Building typologies, material costs, regulatory parameters, historical quantity ratios. Grows independently of any project; compounds in value over time. The system's moat.
