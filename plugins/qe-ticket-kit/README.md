# qe-ticket-kit

Assess and improve Jira tickets, and write structured bug reports.

**Reach for this kit when:** you have a ticket in front of you.

## What's inside

| Type | Name | What it does |
| --- | --- | --- |
| Skill | `bug-reporter` | Interviews you and produces a structured, objective bug report ready to open in Jira. |
| Skill | `story-spec-writer` | Turns an idea into a structured story, task or spike. Asks 3–5 Socratic questions first, then outputs markdown or creates the Jira issue directly. Iterates against the `ticket-quality-analyzer` rubric until it scores 80+. |
| Skill | `ticket-quality-analyzer` | Scores a Jira ticket 0–100 through a QA lens, with a checklist and actionable fixes. Works on demand, in batch, or as a scheduled daily report. |

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
