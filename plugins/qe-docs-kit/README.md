# qe-docs-kit

Generate and refresh code-grounded Confluence documentation for FanDuel services.

**Reach for this kit when:** you need a service documented in Confluence, want to keep
existing service docs from drifting out of sync with the code, or want that same
documentation fed into a team wiki repo as a reviewable PR.

## Core principle

Every claim in the output is traceable to a file and line number. Nothing is generated
from prompting alone — feature names, contracts, and architecture all come from reading
the actual code. No evidence → no claim; it becomes an Open Question instead.

## What's inside

| Type | Name | What it does |
| --- | --- | --- |
| Skill | `auto-documentation` | Orchestrates the whole flow in your context: picks a mode (create one service, sweep several for drift, or report-only), dispatches the extraction agents, assembles the pages, and publishes to Confluence. |
| Agent | `auto-documentation` | The same orchestrator, dispatchable as a subagent — for automation and for other agents that need a service documented without it happening in their own context. |
| Agent | `autodoc-explorer` | Read-only code extraction: stack fingerprint, service compass, contract inventory (Kafka, APIs, databases, schedulers), C4/hexagonal architecture, domain model, and the list of features to document. |
| Agent | `autodoc-deployment-mapper` | Read-only deployment analysis: detects the deployment model, resolves environment config, and maps how the service is built, deployed, verified, and rolled back. |
| Agent | `autodoc-flow-tracer` | Read-only deep dive of one feature: traces the call chain from its entry points, documents business decisions, and produces sequence/decision diagrams. Dispatched once per feature. |
| Agent | `autodoc-reviewer` | Independent check of the assembled drafts against the actual code and the other agents' findings — fixes factual errors and gaps, never touching human-owned sections. |

## Output

One main Confluence page per service, plus one child page per feature:

```
<ServiceName>                       (main page)
├── <ServiceName> — <Feature A>     (child page)
├── <ServiceName> — <Feature B>
└── ...
```

Pages are drafts of truth until a service owner signs the validation checklist on the
main page — the kit never claims the output is final.

## Modes

- **create** — document a single service from scratch. Interactive: asks for the repo and
  the Confluence location if not given.
- **sweep** — refresh only the services/pages whose docs have drifted from the code,
  driven by a config file; can run unattended.
- **report-only** — produce the drift report without publishing anything.

## Quick start

No slash command — ask Claude Code directly, or name the skill explicitly if it doesn't
trigger on its own:

**One service, interactively:**
> "Document the `pcsa-md-service` repo in Confluence" (or: "use auto-documentation to
> document this service"). Answer with the repo path/URL and Confluence `cloud_id` /
> `space_key` / `parent_page_id` when asked.

**Several services, unattended (e.g. scheduled):**
> "Run an auto-documentation sweep using `auto-documentation-config.yaml`"

**Just see what's drifted, change nothing:**
> "Run auto-documentation in report-only mode against `auto-documentation-config.yaml`"

For automation or dispatch from another agent, use the `auto-documentation` agent
directly instead of the skill — same behavior, runs as a subagent so it doesn't consume
the caller's context.

### Config file (`auto-documentation-config.yaml`)

```yaml
confluence:
  cloud_id: fanduel.atlassian.net
  space_key: SPACEKEY
  parent_page_id: 123456789          # default parent page for services below
wiki_ingest:                         # optional — off unless set
  enabled: false
  repo: <path or git URL of a karpathy-llm-wiki-style repo>
  raw_dir: Wiki/raw/sportsbook-services
  branch: main
services:
  - name: PCSA-MD
    repo: https://github.com/Flutter-Global/pcsa-md-service.git
    branch: main
    auto_tier: significant          # significant | all | report-only
  - name: RISK-SVC
    repo: https://github.com/fanduel/risk-service.git
    branch: main
    parent_page_id: 987654321        # this service docs live under a different page
    wiki_ingest: true                # only this service exports to the wiki repo
defaults:
  auto_tier: significant
```

`parent_page_id` and `wiki_ingest` can be set per service — each overrides its top-level
default (`confluence.parent_page_id`, `wiki_ingest.enabled`) for that service only.

An empty or missing config is reported, not an error — the run just stops with
"0 serviços configurados".

## Wiki repo export (optional)

Off by default. When `wiki_ingest.enabled: true` (globally or per service), after a
service's Confluence pages are published the kit also renders the same content to plain
Markdown and opens a PR — never a direct push — against a target wiki repo, as a
raw-source file ready for that repo's own ingest process (e.g. a `karpathy-llm-wiki`
style skill) to compile into its curated pages. One failed export is flagged in the
report and never blocks Confluence publishing or other services.

## Guardrails

- Never invents values — no evidence means an Open Question, not a guess.
- Never deletes or moves Confluence pages, and never touches pages outside the
  service's own subtree.
- Never overwrites human-owned sections ("Objetivo de negócio", "Notas humanas") or a
  page's title once set.
- One repo or page failure never blocks the rest of a sweep.
- Wiki repo export is opt-in and PR-only.
