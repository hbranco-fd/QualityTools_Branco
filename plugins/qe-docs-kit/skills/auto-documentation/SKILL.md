---
name: auto-documentation
description: Generate and keep up to date Confluence documentation for FanDuel services — one main service page plus one child page per feature — grounded in real code (stack, contracts, architecture, domain model, flows, deployment). Supports a create mode and a sweep mode that detects code-vs-docs drift and refreshes only affected pages; can run unattended. Use when the user wants service docs in Confluence, a service page with feature sub-pages, to document a service/repo, or a recurring documentation refresh.
---

# AutoDocumentation

Produces structured, code-grounded documentation for a service repository and publishes it to Confluence:

```
<ServiceName>                       (main page)
├── <ServiceName> — <Feature A>     (child page)
├── <ServiceName> — <Feature B>
└── ...
```

## Run the pipeline

This skill and the `auto-documentation` agent run the **exact same pipeline** — the agent
file is the single source of truth for it, not restated here. Read
[`../../agents/auto-documentation.md`](../../agents/auto-documentation.md) in this plugin
and follow it exactly: Preflight (repo pull, baseline/drift detection, deployment-model
detection), dispatching `autodoc-explorer` / `autodoc-deployment-mapper` /
`autodoc-flow-tracer` via the Agent tool, feature identification, the mandatory
`autodoc-reviewer` loop, Confluence publish, the optional wiki repo export, sweep mode,
the report format, and guardrails.

Dispatch the four subagents the same way whether or not you yourself are running as a
dispatched agent — it keeps your own context lean (real extraction work — hundreds of
Grep/Read calls — stays in the subagent, not here) and guarantees the same review pass
regardless of how AutoDocumentation was invoked. Don't skip the reviewer round just
because you're running inline.

**Core principle, enforced on every subagent you dispatch:** every claim traceable to a
file and line number; no evidence → no claim → Open Question. Feature names and grouping
come from code, not Jira/product docs/existing Confluence — a first draft humans adjust on
the page, which this skill then preserves (see "Human edits" in the agent file).

## Modes

- **create** — one service, interactively. Ask for anything missing: repository path/URL,
  Confluence `cloud_id`/`space_key`/`parent_page_id`, initiative doc (optional),
  deployment model (optional — inferred otherwise).
- **sweep** — all configured services from the config file; detects drift, refreshes only
  what changed; no interactive gate when unattended (selects per `auto_tier`).
- **report-only** — sweep without writing anything.

## Config file

`auto-documentation-config.yaml` (path given by the caller). Schema, field defaults and a
worked example: [`references/config.md`](references/config.md) — that file is the single
source of truth; don't restate the schema elsewhere.

Missing file or empty `services:` → report "0 serviços configurados — nada a fazer" and
stop. Not an error.
