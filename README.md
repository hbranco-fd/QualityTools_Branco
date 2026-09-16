# QualityTools

AI tooling for Claude Code, built from a Quality Engineer's point of view and
packaged as **kits**.

## Purpose

A single place to keep and grow the QE tooling I actually use, under version
control rather than scattered across editor uploads and machine-local config.
This repository is the source of truth: what ships is what is committed here.

The ground it is meant to cover is test design and coverage, defect analysis
and triage, quality reporting, and automation helpers for QA workflows. Not all
of that is built — the table below is the honest inventory of what exists today.

## Kits

Each kit is named after the artefact you have in your hands right now. Install
only the ones that match the work you actually do — there is no need to take
the whole set.

| Kit | Reach for it when | Inside |
| --- | --- | --- |
| [`qe-ticket-kit`](plugins/qe-ticket-kit) | You have a ticket in front of you | `bug-reporter`, `story-spec-writer`, `ticket-quality-analyzer` |
| [`qe-test-plan-kit`](plugins/qe-test-plan-kit) | You need to decide what to test | `cucumber-component-test-writer`, `manual-test-plan-writer`, `pcsa-md-functional-test-plan` |
| [`qe-test-code-kit`](plugins/qe-test-code-kit) | You need to make the tests run | `mason` (agent) |
| [`qe-pr-kit`](plugins/qe-pr-kit) | You have a pull request to deal with | `pr-tier-risk-criticality` (skill + agent), `pr-tier-test-judge` (agent) |
| [`qe-service-kit`](plugins/qe-service-kit) | You need to understand a service | `service-understand`, `datadog-service-catalog-validator`, `support-troubleshooting-guide` |

## Install

```bash
claude plugin marketplace add hbranco-fd/QualityTools_Branco
claude plugin install qe-ticket-kit@quality-tools
```

Installing copies the kit into a version-keyed cache, so editing this repository
does not change an installed kit until you bump its version and update. Full
instructions, including the edit loop, are in [docs/INSTALL.md](docs/INSTALL.md).

## Layout

```
.claude-plugin/marketplace.json   The marketplace manifest - lists every kit
plugins/<kit>/                    One directory per kit
  .claude-plugin/plugin.json      That kit's manifest
  skills/<name>/SKILL.md          Skills
  agents/<name>.md                Agents
  commands/<name>.md              Slash commands
docs/                             Install and contribution guides
templates/                        Starting points for new skills and agents
scripts/validate.sh               Run before committing
```

## Adding something

Read [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md). The short version: copy a
template into the right kit, fill it in, update that kit's README table, bump
its version in both manifests, and run `./scripts/validate.sh`.

## Which kit does this belong in?

Ask what the person is holding when they need it. A skill that reads a Jira
ticket belongs in `qe-ticket-kit` even if it ends up suggesting tests. A skill
that writes step definitions belongs in `qe-test-code-kit` even if it reads the
ticket for context.

If something genuinely spans two kits, that is usually a sign it should be
split into two skills, each with one job.

## Versioning

Each kit carries its own version and moves independently. The version lives in
two places that must agree — `plugins/<kit>/.claude-plugin/plugin.json` and the
matching entry in `.claude-plugin/marketplace.json`. `./scripts/validate.sh`
catches them when they drift.

Changes are recorded in [CHANGELOG.md](CHANGELOG.md).
