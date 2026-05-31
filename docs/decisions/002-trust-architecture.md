# ADR 002 — Three Independently Auditable Tools

**Status:** Decided  
**Date:** Pre-v50

## Decision

The suite is split into three tools (AdriCad, AdriBim, AdriPlan) that share one data foundation but are independently auditable.

## Context

A contractor evaluating pipe routing doesn't need to understand the architecture. An accountant reviewing the budget doesn't need to understand MEP. Each tool must be stress-tested by domain experts who only care about that layer.

## Consequences

- Each tool can be verified independently by its domain expert
- Builds trust faster than a monolithic tool because each party audits only what they understand
- Enables per-tool deployment and per-project pricing
- Tradeoff: shared data model must be maintained carefully — application schema must faithfully reflect core schema, not drift
