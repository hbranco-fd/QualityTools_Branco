# qe-test-code-kit

Implement automated tests - step definitions, component tests, and fixtures.

**Reach for this kit when:** you need to make the tests run.

## What's inside

| Type | Name | What it does |
| --- | --- | --- |
| Agent | `mason` | Implements, extends and reviews Cucumber component tests in whatever repo it is invoked in, reuse-first. Builds a per-repo knowledge pack on first run instead of assuming conventions, and asks before guessing. |

### Supporting files

| Path | Purpose |
| --- | --- |
| `scripts/mason-bootstrap.sh` | Scaffolds the per-repo knowledge pack from the templates. Idempotent; never overwrites a filled pack. |
| `scripts/cucumber-reference/_templates/` | The three skeleton files the bootstrap seeds from. |

The bootstrap resolves its templates relative to its own location, so it works from wherever the plugin is installed. It writes the generated pack into the **target repo** at `.claude/agents/QA/cucumber-reference/`, not into the plugin.

## Layout

| Directory | Holds |
| --- | --- |
| `skills/` | One directory per skill, each with a `SKILL.md` |
| `agents/` | One `.md` file per agent |
| `commands/` | One `.md` file per slash command |
| `scripts/` | Helper scripts and the templates they seed from |

## Adding to this kit

See [CONTRIBUTING.md](../../docs/CONTRIBUTING.md). Keep the table above current —
it is the fastest way for a teammate to tell whether this kit is worth installing.

## Installing

See [INSTALL.md](../../docs/INSTALL.md).
