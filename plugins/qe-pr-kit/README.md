# qe-pr-kit

Decide how much review a PR needs, assess risk, and open PRs to convention.

**Reach for this kit when:** you have a pull request to deal with.

## What's inside

| Type | Name | What it does |
| --- | --- | --- |
| Skill | `pr-tier-risk-criticality` | Scores a pull request on a risk × criticality matrix and decides how much human review it needs — AI-only, one review, one-to-two, or two. Runs in your context, so the diff is there to discuss. Also bootstraps a service's `critical-areas.yaml`. |
| Agent | `pr-tier-risk-criticality` | The same scoring, isolated — pulls the diff itself and returns the verdict without it reaching your context. For automation, and for other agents. |
| Agent | `pr-tier-test-judge` | Judges whether a PR's tests would actually fail if the changed code were broken. Dispatched by the two above; not invoked directly. |

The skill and the agent share one model and give the **same verdict** — they differ only in
where the work happens.

## How the review tier is decided

Two independent questions, crossed in a 2×2. They are never collapsed into a single score.

- **Risk** — how likely is it that this PR introduces a bug? A weighted sum of three
  signals: change size, missing tests, and the fix/revert history of the files touched.
- **Criticality** — how bad is it if one ships? An OR of flags: a sensitive area, a broken
  contract, something irreversible, a customer-facing surface under SLA. Any single hit
  makes it High.

| | Risk Low | Risk High |
| --- | --- | --- |
| **Criticality High** | 1–2 reviews | 2 reviews |
| **Criticality Low** | AI-only | 1 review |

Criticality dominates — one flag and the PR can never land in AI-only, however small it is.
The verdict is advisory: **a person always performs the merge, and nothing here writes code.**

### The test-quality judge

The `Missing tests` signal asks whether the changed lines are covered. It cannot ask whether
the tests are worth anything — so a spec that mocks the API and then asserts the fixture
counts as coverage and buys a lighter tier, while the code it changed never runs.

That is the worst shape a false negative can take: the signal reads *covered*, so nothing
downstream has any reason to doubt it. A PR with **no** tests was always handled correctly;
it is the PR that *looks* tested that slips through.

A separate judge closes the gap. It reads the production diff and the test diff, scores them
on three dimensions — does the changed code actually run, does anything assert the outcome,
and either branch coverage (unit, component) or flakiness (E2E) — and can only ever **raise**
the risk, never lower it. When it penalises, the reason is printed alongside the tier:

```
PR: Risk uncertain (50), Criticality Low → between AI-only and 1 review. I can't call it — please break the tie.
Tests: theatre (relevance) — `route.fulfill({ json: fixture })` at login.spec.ts:24; the changed code never runs.
```

That second line is the only part of the whole tool a developer can act on. Size and file
history they cannot change; "this test would pass with the code broken" they can fix in ten
minutes — and the next PR is genuinely safer rather than merely reviewed harder.

### Calibrating it

The judge measures tests against the rulers in
**[`references/test-quality/`](references/test-quality/)** — one file per dimension, holding
worked examples of solid, thin, weak and theatre tests across Playwright (TypeScript, Python,
Java, .NET), Vitest, pytest, JUnit and Testing Library.

Calibration is a pull request: when the judge gets a call wrong, you add the case that fooled
it. **[`references/test-quality/README.md`](references/test-quality/README.md)** is the guide
— which file, which band, where in the file, and what must never go in. It is written to be
followed by a person or by an agent asked to add an example.

The reasoning behind the whole design — why the judge is penalty-only, why it never sees the
tier, why `theatre` replaces the signal instead of adding to it — is in
[the design document](../../docs/superpowers/specs/2026-09-16-pr-tier-risk-criticality-design.md).

## Layout

| Directory | Holds |
| --- | --- |
| `skills/` | One directory per skill, each with a `SKILL.md` |
| `agents/` | One `.md` file per agent |
| `commands/` | One `.md` file per slash command |
| `references/` | Material the skills and agents read at runtime, not loaded up front |

## Adding to this kit

See [CONTRIBUTING.md](../../docs/CONTRIBUTING.md). Keep the table above current —
it is the fastest way for a teammate to tell whether this kit is worth installing.

To add a test-quality example rather than a skill or an agent, follow
[references/test-quality/README.md](references/test-quality/README.md) instead.

## Installing

See [INSTALL.md](../../docs/INSTALL.md).
