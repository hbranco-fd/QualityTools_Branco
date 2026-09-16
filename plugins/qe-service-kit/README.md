# qe-service-kit

Map and document services - architecture, contracts, and catalog compliance.

**Reach for this kit when:** you need to understand a service.

## What's inside

| Type | Name | What it does |
| --- | --- | --- |
| Skill | `service-understand` | Analyses a service repo and produces stack, purpose, contracts, architecture diagrams, domain model, flows and deployment docs, plus ecosystem-level city map and contract registry. |
| Skill | `datadog-service-catalog-validator` | Validates and fixes `service.datadog.yaml` against the FanDuel v2.2 tag baseline. |
| Skill | `support-troubleshooting-guide` | Builds a support and on-call runbook Confluence page for a service — flow, dependencies, monitoring and common failures. |

## Layout

| Directory | Holds |
| --- | --- |
| `skills/` | One directory per skill, each with a `SKILL.md` |
| `agents/` | One `.md` file per agent |
| `commands/` | One `.md` file per slash command |

## Adding to this kit

See [CONTRIBUTING.md](../../docs/CONTRIBUTING.md). Keep the table above current —
it is the fastest way for a teammate to tell whether this kit is worth installing.

## Installing

See [INSTALL.md](../../docs/INSTALL.md).
