-- AdriSuite Core Project Schema
-- Supabase/PostgreSQL
-- Status: Skeleton — domain boundaries and granularity TBD
--
-- Key decisions pending:
--   - Right level of granularity (wall as one object vs. layers)
--   - Domain boundary placement (staircase: space, structure, or circulation?)
--   - Israeli market specifics — municipal patterns, contractor relationships
--   - What needs procurement-grade vs. design-grade trust

-- ============================================================
-- PROJECTS
-- ============================================================

create table projects (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  description text,
  typology    text,               -- e.g. 'residential_multi', 'commercial', 'mixed_use'
  municipality text,              -- Israeli municipality — drives regulatory fingerprints
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- ============================================================
-- SPACES
-- ============================================================

create table spaces (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid references projects(id) on delete cascade,
  name        text not null,
  type        text,               -- 'bedroom', 'living', 'kitchen', 'bathroom', 'circulation', etc.
  area_sqm    numeric,
  height_m    numeric,
  floor       integer,
  created_at  timestamptz default now()
);

-- ============================================================
-- ELEMENTS
-- Elements are the physical building components.
-- Each element belongs to a space and has a system classification.
-- ============================================================

create table elements (
  id              uuid primary key default gen_random_uuid(),
  project_id      uuid references projects(id) on delete cascade,
  space_id        uuid references spaces(id) on delete set null,
  type            text not null,  -- 'wall', 'slab', 'column', 'beam', 'window', 'door', etc.
  material        text,
  quantity        numeric,
  quantity_unit   text,           -- 'sqm', 'lm', 'units', 'kg'
  -- Constructability attributes (for AdriSnap)
  approach_vector jsonb,          -- {x, y, z} unit vector for placement approach
  tolerance_mm    numeric,        -- final placement tolerance in mm
  sequence_pos    integer,        -- assembly sequence position
  temp_works      text,           -- temporary works required: 'none', 'shoring', 'formwork', etc.
  -- Trust level
  confidence      numeric,        -- 0–1: model completeness confidence for this element
  created_at      timestamptz default now()
);

-- ============================================================
-- SYSTEMS
-- MEP systems — each system is a directed graph of components
-- from experience node back to source node (AdriBim domain)
-- ============================================================

create table systems (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid references projects(id) on delete cascade,
  type        text not null,      -- 'plumbing_supply', 'plumbing_drain', 'hvac', 'electrical', 'gas'
  name        text,
  created_at  timestamptz default now()
);

create table system_nodes (
  id              uuid primary key default gen_random_uuid(),
  system_id       uuid references systems(id) on delete cascade,
  type            text not null,  -- 'experience', 'device', 'distribution', 'source'
  label           text,           -- e.g. 'shower', 'showerhead', 'supply_pipe', 'riser', 'meter'
  space_id        uuid references spaces(id) on delete set null,
  element_id      uuid references elements(id) on delete set null,
  spec            jsonb,          -- type-specific specs (flow rate, pipe diameter, etc.)
  created_at      timestamptz default now()
);

-- Directed edges: upstream_id → downstream_id (source toward experience)
create table system_edges (
  id            uuid primary key default gen_random_uuid(),
  system_id     uuid references systems(id) on delete cascade,
  upstream_id   uuid references system_nodes(id) on delete cascade,
  downstream_id uuid references system_nodes(id) on delete cascade
);

-- ============================================================
-- COSTS
-- Model-derived — computed from elements, not re-entered
-- ============================================================

create table cost_items (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid references projects(id) on delete cascade,
  element_id  uuid references elements(id) on delete set null,
  category    text,               -- 'structure', 'envelope', 'mep', 'finishes', 'site'
  description text,
  quantity    numeric,
  unit        text,
  unit_cost   numeric,            -- ILS
  total_cost  numeric generated always as (quantity * unit_cost) stored,
  confidence  numeric,            -- 0–1: mirrors element confidence
  created_at  timestamptz default now()
);

-- ============================================================
-- SCHEDULE (AdriPlan → AdriSnap bridge)
-- ============================================================

create table schedule_phases (
  id            uuid primary key default gen_random_uuid(),
  project_id    uuid references projects(id) on delete cascade,
  label         text not null,
  type          text,             -- 'exc', 'foundation', 'structure', 'envelope', 'mep', 'finishes'
  start_date    date,
  finish_date   date,
  duration_wks  numeric,
  floor_tag     text,
  status        text default 'planned',  -- 'planned', 'active', 'complete'
  parallel      boolean default false,
  sequence_pos  integer,
  created_at    timestamptz default now()
);

-- ============================================================
-- UPDATED_AT triggers
-- ============================================================

create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger projects_updated_at
  before update on projects
  for each row execute function set_updated_at();
