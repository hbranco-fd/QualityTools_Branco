# qe-pr-kit

Decide how much review a PR needs, assess risk, and open PRs to convention.

**Reach for this kit when:** you have a pull request to deal with.

## What's inside

| Type | Name | What it does |
| --- | --- | --- |
| Skill | `fiscal-de-linha` | Scores a pull request on a risk × criticality matrix and decides how much human review it needs — AI-only, one review, one-to-two, or two. Bootstraps a service's `critical-areas.yaml` on first run. |

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
