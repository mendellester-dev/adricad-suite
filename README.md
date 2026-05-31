# AdriSuite

Trust infrastructure for the building process.

Four tools sharing one directed-graph data model, each independently auditable by domain experts.

| Tool | Role | Deploy |
|---|---|---|
| [AdriCad](tools/adricad/) | 3D geometry definition — the design input | adriCAD.com / Netlify |
| [AdriBim](tools/adribim/) | MEP coordination + plumbing routing | adriBIM.com / Netlify |
| [AdriPlan](tools/adriplan/) | Model-derived cost + schedule | adriPlan.com / Netlify |
| [AdriSnap](tools/adrisnap/) | Construction sequence + block assembly | adriSnap.com / Netlify |

## Structure

```
tools/          Each tool as a self-contained index.html
docs/           Vision, architecture, roadmap, decisions
schema/         Supabase SQL schema + intelligence layer JSON
deploy/         Netlify and Cloudflare config
CHANGELOG.md    Version history (replaces numbered BCP folders)
```

## Development

Each tool is a single HTML file — open directly in a browser to run locally.

```bash
open tools/adricad/index.html
open tools/adribim/index.html
open tools/adriplan/index.html
open tools/adrisnap/index.html
```

## Versioning

Git tags replace the BCP numbered folder system.

```bash
git tag v51 -m "description of what changed"
```

See [CHANGELOG.md](CHANGELOG.md) for full history.

## Deploy

See [deploy/](deploy/) for Netlify and Cloudflare configs.
Supabase schema lives in [schema/](schema/).
