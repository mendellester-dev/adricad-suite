# ADR 001 — Procedural, Not Parametric

**Status:** Decided  
**Date:** Pre-v50

## Decision

AdriSuite tools apply rules freshly on each change rather than maintaining a web of interdependencies between elements (parametric approach).

## Context

Parametric tools (Revit) connect everything through constraint webs — move a wall and three door schedules break. The model becomes increasingly load-bearing as it grows until it manages the user rather than the reverse. Navigating this requires years of accumulated BIM operator expertise.

## Consequences

- No cascading failures when geometry changes
- No BIM manager required
- Can ask for a different layout and receive a valid, coordinated result — something Revit cannot do
- Makes the system accessible to the 95% Revit excludes (small practices, design-build operators, developer-architects)
- Tradeoff: less automatic propagation of changes across dependent elements — must be handled explicitly in code
