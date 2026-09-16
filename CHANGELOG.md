# Changelog

Notable changes to the kits in this repository. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

Each kit is versioned independently, so entries name the kit they apply to.
Changes that affect the repository itself rather than a kit are filed under
_Repository_.

## [Unreleased]

### Added

- **`qe-pr-kit` 0.2.0** — a test-quality judge, and a second way to run the
  tiering.

  The `Missing tests` signal asked whether changed lines were covered, never
  whether the tests were worth anything — so a spec that mocked the API and
  asserted the fixture counted as coverage and bought a lighter review tier
  while the changed code never ran.

  - `pr-tier-test-judge` (agent) — reads the production diff and the test diff
    and scores them on three dimensions: whether the changed code actually
    runs, whether anything asserts the outcome, and either branch coverage
    (unit, component) or flakiness (E2E). Penalty-only: it can raise the risk,
    never lower it. It never sees the tier or the other signals.
  - `pr-tier-risk-criticality` (agent) — the scoring run in an isolated
    context, for automation and for other agents. Same model, same verdict as
    the skill.
  - `references/tiering-model.md` — the axes, weights, thresholds, flags and
    matrix, moved out of the skill so the two entry points cannot drift apart.
  - `references/test-quality/` — the rulers the judge measures against, with
    worked examples across Playwright (TypeScript, Python, Java, .NET),
    Vitest, pytest, JUnit and Testing Library. Calibrating the judge means
    adding to these files; the guide is in their `README.md`.

- **Repository** — initial scaffolding: the `quality-tools` marketplace and
  five kits, plus install and contribution guides, skill and agent templates,
  and `scripts/validate.sh`.

- **All kits** — first migration. Ten skills and one agent moved in from the
  places they were living unversioned, making this repository their source of
  truth:

  | Kit | Brought in | From |
  | --- | --- | --- |
  | `qe-ticket-kit` | `bug-reporter`, `ticket-quality-analyzer` | Claude desktop uploads |
  | `qe-ticket-kit` | `story-spec-writer` | `ticket-toolkit` plugin |
  | `qe-test-plan-kit` | `cucumber-component-test-writer`, `manual-test-plan-writer`, `pcsa-md-functional-test-plan` | Claude desktop uploads |
  | `qe-test-code-kit` | `mason` agent, its bootstrap script and knowledge-pack templates | `~/.claude/agents/QA/` |
  | `qe-pr-kit` | `fiscal-de-linha` | Claude desktop uploads |
  | `qe-service-kit` | `service-understand`, `datadog-service-catalog-validator`, `support-troubleshooting-guide` | Claude desktop uploads |

  Every copy was verified byte-identical to its source.

### Changed

- **`qe-pr-kit` 0.2.0** — the `fiscal-de-linha` skill is now
  `pr-tier-risk-criticality`. The name is the dispatch handle and says what the
  tool does, which the metaphor did not. Its scoring rules moved to
  `references/tiering-model.md`; it keeps bootstrap mode, which is a
  conversation rather than a scoring run.

  Anything referring to the old name needs updating —
  including `~/.claude/agents/pr.md`, which lives outside this repository and
  carries its own copy of the tiering model.

### Notes on what was left behind

- `writing-plans` was not migrated. The uploaded copy is byte-identical to the
  one the `superpowers` plugin already provides, so it was a duplicate rather
  than an asset.
- Only `cucumber-reference/_templates/` came across with `mason`. The three
  `.md` files sitting beside them were scaffolding residue from a bootstrap run
  in a home directory, identical to the templates they came from.
- Career skills (`dev-plan`, `evidence-log-weekly-updater`, and the
  `personal-dev` plugin) and utilities (`caveman`, `grill-me`,
  `publish-fanduel-pages`) are deliberately out of scope for now. They remain
  unversioned.
- `cucumber-component-test-writer` and `manual-test-plan-writer` also exist in
  the team's `grizzlies-utils` repository. The copies here are personal and will
  not track changes made there.
