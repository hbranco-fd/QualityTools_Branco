# `auto-documentation-config.yaml` — schema

This is the **single source of truth** for the config file schema used by sweep /
report-only mode. The `auto-documentation` skill, the `auto-documentation` agent, and
the plugin README all point here instead of restating it — update only this file when
the schema changes.

```yaml
confluence:
  cloud_id: <site, e.g. fanduel.atlassian.net>
  space_key: <SPACEKEY>
  parent_page_id: <default — id of the page under which service pages live>
wiki_ingest:
  enabled: false                 # master switch — off by default
  repo: <path or git URL of a karpathy-llm-wiki-style repo>
  raw_dir: <path inside that repo, e.g. Wiki/raw/sportsbook-services>
  branch: main                   # base branch the PR targets
services:
  - name: PCSA-MD
    repo: https://github.com/Flutter-Global/pcsa-md-service.git
    branch: main
    page_id: <optional — set after first run; else found by title>
    parent_page_id: <optional — overrides confluence.parent_page_id for this service>
    config_repo: <optional — overrides Preflight discovery>
    deployment_model: <optional — v2 | vm-evo | podium>
    auto_tier: significant      # significant | all | report-only
    wiki_ingest: <optional — true|false, overrides the master switch for this service>
defaults:
  auto_tier: significant
```

## Fields

| Field | Scope | Default when omitted |
|---|---|---|
| `confluence.cloud_id`, `confluence.space_key` | global | — (required) |
| `confluence.parent_page_id` | global | — (required unless every service sets its own) |
| `wiki_ingest.enabled` | global | `false` |
| `wiki_ingest.repo`, `wiki_ingest.raw_dir`, `wiki_ingest.branch` | global | `branch` defaults to `main`; `repo`/`raw_dir` required only if any service has wiki export on |
| `services[].parent_page_id` | per service | `confluence.parent_page_id` |
| `services[].wiki_ingest` | per service | `wiki_ingest.enabled` |
| `services[].page_id`, `config_repo`, `deployment_model` | per service | discovered by Preflight |
| `services[].auto_tier` | per service | `defaults.auto_tier` |

A per-service field **overrides** the matching global/default value for that service only;
omitting it means "inherit." Every mention of `parent_page_id` elsewhere in the skill/agent
docs means a service's own **resolved** value (its override if set, else
`confluence.parent_page_id`) — so Phase 2b sibling matching and "never edit outside the
subtree" only ever consider pages under that same resolved principal page.

## Two-service example

```yaml
confluence:
  cloud_id: fanduel.atlassian.net
  space_key: SPACEKEY
  parent_page_id: 123456789
wiki_ingest:
  enabled: false
  repo: /path/to/risk-trading-and-catalog-wiki
  raw_dir: Wiki/raw/sportsbook-services
  branch: main
services:
  - name: PCSA-MD
    repo: https://github.com/Flutter-Global/pcsa-md-service.git
    branch: main
    auto_tier: significant
  - name: RISK-SVC
    repo: https://github.com/fanduel/risk-service.git
    branch: main
    parent_page_id: 987654321    # lives under a different Confluence page
    wiki_ingest: true            # only this service exports to the wiki repo
defaults:
  auto_tier: significant
```

## Missing or empty config

Missing file, or `services:` empty/absent → report "0 serviços configurados — nada a
fazer" and stop. Not an error.
