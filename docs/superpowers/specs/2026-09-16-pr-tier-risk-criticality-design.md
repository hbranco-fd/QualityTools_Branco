# PR Tier: Risk × Criticality — agent, judge, and a shared model

**Date:** 2026-09-16
**Status:** Design approved, not implemented
**Supersedes:** the `fiscal-de-linha` skill shipped in `qe-pr-kit` 0.1.0

---

## The problem

The tiering model scores **Risk** as a weighted sum of three signals. One of them —
`Missing tests`, weight 35 — asks whether the changed lines have test coverage in the
same PR. It never asks whether those tests are worth anything.

So a PR that adds a Playwright spec which mocks the API and then asserts the fixture
scores ~10 on that signal and buys itself a lower tier. The coverage is theatre and the
tiering rubber-stamps it.

This is the worst shape a false negative can take: the signal reads *covered*, so nothing
downstream has any reason to question it. A PR with no tests at all is handled correctly
today — it is the PR that *looks* tested that slips through.

## What changes

1. **The model moves to a file.** Axes, weights, thresholds, criticality flags and the
   matrix leave the skill and live in `references/tiering-model.md` — one copy, read by
   every entry point.
2. **Two entry points.** The skill stays (in-context, conversational). A new agent is
   added (isolated, fire-and-forget). Same model, same verdict.
3. **A judge.** A new sub-agent, `pr-tier-test-judge`, corrects the coverage signal when
   it claims the change is covered.
4. **Rename.** `fiscal-de-linha` → `pr-tier-risk-criticality`.

## Pieces

```
plugins/qe-pr-kit/
├── agents/
│   ├── pr-tier-risk-criticality.md    isolated scoring run
│   └── pr-tier-test-judge.md          the judge
├── references/
│   ├── tiering-model.md               single source of truth for the model
│   └── test-quality/                  the judge's rulers
│       ├── relevance.md
│       ├── assertions.md
│       ├── branches.md
│       └── determinism.md
└── skills/
    └── pr-tier-risk-criticality/
        └── SKILL.md                   in-context scoring + bootstrap mode
```

`references/` sits at kit root, not under `agents/`. `agents/` is scanned for agent
definitions; putting non-agent `.md` files there invites the loader to register them.

## Entry points

The two differ in **where the work happens**, never in the answer.

| | Skill | Agent |
|---|---|---|
| Context | the caller's | isolated |
| The diff | lands in the conversation — useful when you want to discuss it | never leaves the agent |
| The judge | dispatched, when `Agent` is available | dispatched |
| Bootstrap mode | yes | no — reports the gap instead |
| For | reading, discussing, iterating | automation, other agents, verdict only |
| Verdict | **identical** | **identical** |

Both read `references/tiering-model.md`. Because the model has one copy, it does not
matter which one gets invoked — the overlap in their trigger surfaces is harmless.

**Bootstrap lives in the skill.** Proposing a `critical-areas.yaml` for a human to curate
is a conversation, and it runs once per service. Keeping it out of the agent also keeps a
cold path out of every scoring run. An agent that finds no `critical-areas.yaml` scores
with universal criticality signals and says so.

## The judge

### The signal it acts on

The judge moves one number: the model's `Missing tests` signal, weight 35.

**Read its direction carefully — it measures absence, not coverage.** `0` means the changed
lines are fully covered; `100` means there are no tests. Everything below is phrased in
those terms, and "the signal goes up" always means *less trustworthy*.

### Contract

**Penalty-only.** The judge can raise `Missing tests`, never lower it below what the
deterministic check already produced. Rewarding good tests is where an LLM judge errs most
and where the error costs most — it would wave through a PR that needed a human.

### When it runs

Only when the deterministic `Missing tests` signal is **below 70** — that is, only when the
check believes the change is reasonably covered.

This falls out of the contract rather than being a separate tuning knob: if the judge can
only raise the signal, it has nothing to do when the signal is already high. A PR with no
tests sits at ~90-100 and there is no room to add. The judge earns its cost exactly where
the check says *this is covered, relax* — which is where the check lies.

### What it receives

The **production diff** and the **test diff**. Nothing else.

It does **not** receive the tier, the size signal, the hotspot signal, or the criticality
verdict. A judge that knows saying `theatre` costs two reviewers is no longer independent.

### The rubric

Two dimensions hold at every test level. The third swaps, which forces the judge to
classify the level first and say so — making a misclassification visible.

| | Dimension | The question |
|---|---|---|
| 1 | `relevance` | Would this fail if you broke the changed line? |
| 2 | `assertions` | Does it assert the *outcome*, or only that something exists / nothing threw? |
| 3 | *by level* | unit / component → `branches` · E2E → `determinism` |

- `branches` — are the new branches and error paths covered, or only the happy path?
  Capped at `weak`.
- `determinism` — hard waits, brittle selectors, state shared between specs. Capped at
  `thin`. A `waitForTimeout` is a smell, not a fraud; it cannot weigh the same as a test
  that asserts nothing.

`relevance` absorbs over-mocking. In a front-end PR, mocking the network is *correct*
behaviour, not a defect. The theatre is a mock that returns the exact shape the test then
asserts, with none of the changed code doing work in between.

**The worst dimension sets the verdict.** Not the sum — the same reasoning already applied
to the Criticality axis: one strong reason must not be diluted by weak ones. Summing would
let a test with flawless assertions that never touches the changed branch look acceptable.

**The judge judges the ensemble**, not file by file. Coverage is a property of the set. One
weak spec among four good ones must not drag the verdict; one solid unit test does not
excuse an E2E that misses what changed.

### The bands

Each band is defined by the bug it would catch:

```
solid     +0     would catch the bug
thin      +20    would catch some of it
weak      +40    would probably miss it
theatre   → 95   cannot catch it — treat as untested
```

Because of the caps, **only `relevance` and `assertions` can reach `theatre`**. Flakiness
or a missing branch never means *these tests do not exist*; "would not fail if you broke
the line" and "asserts nothing" both do.

`theatre` is not a penalty. It is the finding that there are no tests. A test that passes
with the code broken carries zero information and is indistinguishable from absence — so
the signal is set to the no-tests value rather than nudged.

Why this matters, in numbers. A front-end PR, 3 files, with a spec that mocks the API and
asserts the fixture:

```
size 30 · hotspot 20 · deterministic Missing tests = 10   (the check says: covered)

as an additive +60:   risk = .35(30) + .35(70) + .30(20) = 41  → Risk Low
as signal = 95:       risk = .35(30) + .35(95) + .30(20) = 50  → uncertain, human breaks the tie
```

With the harshest band the rubric allows, an additive penalty leaves the PR at Risk Low —
the judge diagnoses fraud and changes nothing, because weight 35 dilutes +60 into 21 points
of risk.

Note what still holds: **the judge alone does not push a PR to `2 reviews`.** On a small
change in a quiet file, total theatre reaches 50 — uncertainty, not Risk High. Reaching
High needs size or history pulling too. That is intended: three signals, none of them
deciding alone.

### What it returns

The band, the dimension that caused it, the citation, and the consequence. Nothing else.

## Calibration

The rulers are **files in the plugin**, not prose in the agent. Calibrating the judge means
opening a PR against `references/test-quality/` and adding the case that fooled it. The
judge improves through use instead of rotting.

**One file per dimension**, so the judge loads only what it needs — an E2E PR never reads
`branches.md` — and so calibration can be precise: when the judge is soft on relevance, the
counter-example has a home.

Each entry carries **code · band · stack/level · why**. The `why` is not decoration: it is
what teaches the judge to write the consequence in its own verdict. Examples without
reasoning teach it to match syntax; examples with reasoning teach it the principle.

````markdown
## theatre · playwright-e2e

```ts
await page.route('**/api/cart', r => r.fulfill({ json: { total: 42 } }));
await expect(page.getByTestId('total')).toHaveText('42');
```

**Why:** the mock returns the number the test asserts. The formatting, rounding and
currency conversion this PR changed never run — the test passes with that function
deleted.
````

**The ruler is absolute; the repo only supplies accent.** The judge may read a neighbouring
test to learn the framework and assertion convention, so it does not flag
`assertThat(x).isEqualTo(y)` as odd merely because it expected `assertEquals`. It never
reads the repo to lower the bar.

Calibrating per-repo would be circular: the repo with the worst tests would contribute its
worst tests as *good* and disarm its own judge. The place you need the judge most is exactly
where it would go easiest on you.

## Output

One line, as today. A second line **only when the judge penalised** — silent on `solid`.

```
PR: Risk uncertain (50), Criticality Low → between AI-only and 1 review. I can't call it — please break the tie.
Tests: theatre (relevance) — `route.fulfill({ json: fixture })` at login.spec.ts:24; the changed code never runs.
```

The tier is a **decision**; the judge's finding is the only part of the whole tool that is
**actionable**. Size and history a developer cannot change. "This test would pass with the
code broken" they can fix in ten minutes.

That is also where the compounding is. A tool that silently routes theatre to heavier review
leaves the tests as theatre forever and the review cost never falls. One that says what it
saw gets the test fixed, and the next PR is genuinely safer. A linesman is useful because
the players learn where the line is.

## Hard rules

1. **Penalty-only.** The judge never lowers `Missing tests` below what the deterministic
   check produced.
2. **The judge never sees the tier**, the other risk signals, or the criticality verdict.
3. **No citation from the diff, no band.** If it cannot point at the line that supports the
   penalty, it does not penalise. This is the guard against invented defects.
4. **The `why` is a consequence, not a rule violation.** "Uses `waitForTimeout`" is a style
   complaint. "Would pass even if the button never became enabled" is what gets it fixed.
5. **Only `relevance` and `assertions` reach `theatre`.** `branches` caps at `weak`,
   `determinism` at `thin`.
6. **Judge the ensemble**, not file by file.
7. **The rulers are the standard.** The repo supplies framework and assertion convention
   only, never the bar.
8. **If the judge cannot run, do not pretend.** Fall back to the deterministic signal and
   say so in the output: `Missing tests = deterministic check only, judge unavailable`.
   Silent degradation is the failure mode to avoid — a tier issued as if nothing were
   missing.
9. **Never merge, never write code.** Unchanged from 0.1.0.

## Known limitations

- **Behaviour-preserving changes are penalised as untested.** Pure refactors, renames and
  dependency bumps carry no test changes and take the full no-tests penalty. This is a
  property the tiering already has; the judge neither worsens nor fixes it.
- **E2E-only coverage living outside the PR is not counted.** By house rule a change that
  alters behaviour brings its test changes with it, so no tests in the PR means no evidence
  of coverage in the PR. Penalising is correct, not conservative.
- **The judge alone cannot reach `2 reviews`.** By design; see the arithmetic above.
- **Weights (35/35/30) and thresholds (55, band 45-55) are defaults, not calibrated truth.**
  Unchanged from 0.1.0.
- **`~/.claude/agents/pr.md` holds a third copy of the model** at
  `$PIPELINE/skills/pr-risk-tiering.md`, and prints "Fiscal de Linha" into Slack. It is
  outside this repo and outside this change, but it will drift from the model here.

## To verify at implementation

- **How the judge resolves the path to `references/`.** `${CLAUDE_PLUGIN_ROOT}` is
  documented for hooks and commands, where it expands in a shell; an agent uses `Read`,
  which wants an absolute path. Planned approach: the parent — which has `Bash` — resolves
  the path and passes it in the dispatch prompt, so the judge keeps `Read, Grep, Glob` and
  never needs to know where it is installed. Fallback: `Glob` for
  `**/references/test-quality/`.
- **Nesting depth.** Sub-agents may spawn sub-agents to 3 levels by default, controlled by
  `tools: Agent(pr-tier-test-judge)`. At the limit the `Agent` tool is withheld. From a
  normal session the chain is `agent (1) → judge (2)` with headroom; hard rule 8 covers the
  case where there is none.

## Renaming

Four references in this repo:

| | |
|---|---|
| `README.md:27` | kit table |
| `plugins/qe-pr-kit/README.md:11` | contents table |
| `plugins/qe-pr-kit/skills/fiscal-de-linha/` | directory, frontmatter `name`, description, headings, body |
| `CHANGELOG.md:28` | **leave as is** |

The changelog line sits in the historical record of what 0.1.0 imported, and in 0.1.0 the
thing *was* called `fiscal-de-linha`. Editing it does not remove the old name, it makes the
changelog lie about what happened. A new entry records the rename instead.
