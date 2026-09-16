# Changelog

Notable changes to the kits in this repository. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

Each kit is versioned independently, so entries name the kit they apply to.
Changes that affect the repository itself rather than a kit are filed under
_Repository_.

## [Unreleased]

### Added

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
