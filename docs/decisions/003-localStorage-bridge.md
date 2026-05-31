# ADR 003 — localStorage + BroadcastChannel as Inter-Tool Bridge (Temporary)

**Status:** Active / To Be Replaced  
**Date:** Pre-v50

## Decision

Inter-tool data sync currently uses `AdriBridge` (BroadcastChannel + `adri:platform` localStorage key). AdriPlan pushes schedule data to AdriSnap via `adri:snap:schedule` key and `adriSync` URL param (BASE64).

## Context

No Supabase backend existed when the tools were built. localStorage provides a zero-infrastructure session-level bridge that works when tools are open in the same browser.

## Consequences

- Works locally with no backend dependency
- Breaks across devices, browsers, and sessions
- No persistence beyond the local browser
- **Planned replacement:** Supabase core project schema as authoritative source of truth. BroadcastChannel kept for real-time tab sync only.

## Migration Path

1. Define core project schema in Supabase (see schema/core-project.sql)
2. Replace `adri:platform` writes with Supabase upserts
3. Replace `adri:platform` reads with Supabase queries
4. Keep BroadcastChannel for low-latency same-session UI updates
