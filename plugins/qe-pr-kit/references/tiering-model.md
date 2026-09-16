# The tiering model

**The single source of truth for how a PR's review tier is decided.** Both entry points —
the `pr-tier-risk-criticality` skill and the agent of the same name — read this file and
follow it exactly. Nothing that scores a PR may carry its own copy of these rules.

Reference design (full rationale): Confluence "PR Review Tiering Agent — Risk × Criticality
Matrix" (page 311876551539, SBK space).

---

## The core model — do not deviate

Two **independent** axes. Never mix them into a single score.

| | Risk Low | Risk High |
|---|---|---|
| **Criticality High** | 1–2 reviews | 2 reviews |
| **Criticality Low** | AI-only | 1 review |

- **Risk** = probability this PR introduces a bug. A **weighted sum** → threshold.
- **Criticality** = severity of the damage if a bug ships. An **OR of flags** → any hit = High.

Criticality **dominates**: if Criticality is High, the PR can never land in AI-only, even
with Risk Low.

---

## Axis 1 — Risk (weighted sum → threshold)

Three signals, each scored 0–100, then combined. **Do the arithmetic and be able to show it**
— this axis must be reproducible.

| Signal | Weight | How to score it (0–100) |
|---|---|---|
| Change size | 35 | Files + lines changed. **Exclude auto-generated files** (lockfiles, codemods, mass renames, generated clients). Rough guide: ≤2 files / ≤50 lines → ~10-20; several files / moderate lines → ~40-60; many files / large diff → ~80-100. Weight files more than lines. |
| Missing tests | 35 | See below — this is the signal the judge can correct. |
| File hotspot history | 30 | From `git log` on touched files: frequent recent fix/revert commits, or files linked to past bugs → high. No churn → ~0-20. Occasional fixes → ~40-60. Known hotspot / recent reverts → ~80-100. |

```
risk_score = round(0.35*size + 0.35*tests + 0.30*hotspot)
```

- **risk_score > 55** → **Risk High**
- **risk_score < 45** → **Risk Low**
- **45–55** → **uncertain**. Do not auto-decide. Report both candidate tiers and hand the
  tie to a human.

### The `Missing tests` signal

**It measures absence, not coverage.** `0` means the changed lines are fully covered; `100`
means there are no tests. "The signal goes up" always means *less trustworthy*.

**Step 1 — the deterministic check.** Do the **new or changed lines** have test coverage in
this same PR? Fully covered → ~0-10. Partially → ~40-60. New logic with no tests → ~90-100.
**Only count coverage of changed lines**, never the whole file — that would penalise legacy
files unfairly.

**Step 2 — the judge, only when the deterministic check is below 70.** Above that the PR is
already being penalised for missing tests and there is nothing a penalty-only judge can add.

Dispatch the `pr-tier-test-judge` sub-agent with the production diff and the test diff.
Give it **nothing else** — not the tier, not the other signals, not the criticality verdict.
Apply its verdict:

| Band | Effect on the signal |
|---|---|
| `solid` | +0 |
| `thin` | +20 |
| `weak` | +40 |
| `theatre` | **signal = 95** — not a penalty, a finding that there are no usable tests |

`theatre` replaces rather than adds: a test that passes with the code broken carries zero
information and is indistinguishable from absence, so the signal is set to the no-tests
value. An additive penalty would be diluted by weight 35 into ~21 points of risk and change
nothing.

The judge can only ever **raise** the signal, never lower it below what the deterministic
check produced.

**If the judge cannot be dispatched** — the `Agent` tool is unavailable, or the nesting depth
limit withheld it — **do not pretend**. Use the deterministic value and say so in the output:

```
Missing tests = deterministic check only, judge unavailable
```

Silent degradation is the failure to avoid: a tier issued as if nothing were missing.

---

## Axis 2 — Criticality (OR of flags → High)

**No arithmetic.** Check each flag as yes/no. **Any single hit → Criticality High.** Multiple
weak reasons do not substitute for one strong reason.

**Flag A — Sensitive area hit.** Does any changed path match an entry in
`critical-areas.yaml`? (Glob match on `path`.) If yes → High, and note the matched entry's
`owner` and `reason`.

**Flag B — Incompatible contract break.** Two layers, run both:

- **Layer 1 (deterministic).** For contract files (`.avsc`, `.proto`, `openapi.yaml`, GraphQL
  SDL, Kafka schemas): diff old vs new. A field **removed or changed** (type change,
  tightened requirement, renamed) = break. A field or event **added** = compatible, NOT a
  break. Renaming a field in a consumed event = removed + added = break.
- **Layer 2 (semantic).** For breaks the diff cannot see — meaning changed without format
  change, contract logic spread through normal code — read and judge. A second net, not the
  only one.

Either layer firing → High.

**Flag C — Irreversible.** Migrations, destructive deletes, anything without an easy
rollback → High.

**Flag D — Customer-facing + high availability.** Directly user-visible surface with a strict
SLA → High.

```
criticality = High if (A or B or C or D) else Low
```

If there is no `critical-areas.yaml`, Flag A cannot fire. Evaluate B, C and D, and say in the
output that the file was absent.

---

## Cross the matrix → tier

| Cell | Tier | What it means |
|---|---|---|
| Risk Low + Crit Low | **AI-only** | No human reviewer required; owner merges. |
| Risk High + Crit Low | **1 review** | One reviewer, no extra ceremony. |
| Risk Low + Crit High | **1–2 reviews** | One reviewer required; a second (the area `owner`) if the change touches something sensitive inside the zone. |
| Risk High + Crit High | **2 reviews** | Two reviewers incl. the area `owner`; QA signalled before merge. |

---

## Output

**Default: one line.** Compute everything internally and report only the verdict. Do not dump
the signal breakdown unless asked "why" / "porquê" / "mostra o detalhe".

**Clear case:**

```
PR: Risk <Low/High>, Criticality <Low/High> → <tier>. Reviewed by <who>.
```

`<who>` — "AI only (owner merges)" · "1 reviewer" · "1 reviewer (+ <owner> if it touches
something sensitive)" · "2 reviewers incl. <owner>, QA signalled".

**Uncertain case** (risk score in the 45–55 band) — do not pick:

```
PR: Criticality <Low/High>, Risk uncertain (score <n>, in the 45–55 band) → between <tier A> and <tier B>. I can't call it — please break the tie.
```

**Second line, only when the judge penalised** — silent on `solid`:

```
Tests: <band> (<dimension>) — <citation from the diff>; <what bug slips through>.
```

The tier is a decision; the judge's finding is the only part of this tool a developer can
act on. Print it.

**If asked why**, expand:

```
Risk <Low/High> (score <n>/100): size <n>, tests <n>, hotspot <n>.
Criticality <Low/High>: sensitive area <hit/no>, contract break <hit/no>, irreversible <yes/no>, customer-facing <yes/no>.
```

---

## Hard rules

1. **Never merge. Never edit or write code.** Advisory output only.
2. **The two axes stay separate.** Risk is a weighted sum; Criticality is an OR of flags.
   Never collapse them into one number.
3. **Criticality dominates.** Any criticality flag → never AI-only.
4. **Contract break = removed or changed field, not added.** Adding is compatible.
5. **Coverage counts changed lines only**, never the whole file.
6. **Change size excludes auto-generated files.**
7. **The judge is penalty-only** and never sees the tier or the other signals.
8. **If the judge cannot run, say so.** Never issue a tier as if it had.
9. Weights (35/35/30) and thresholds (55, band 45–55) are a starting point, not calibrated
   truth. If the user has calibration data, use it; otherwise state that these are defaults.

---

## Worked example

A PR renames `marketId` → `mktId` in a Kafka Avro schema consumed by the Hub. 3 files, has
tests.

- **Risk:** size ~25 (3 files, mechanical), tests ~10 (covered; judge runs, returns `solid`,
  +0), hotspot ~20 → `round(.35*25 + .35*10 + .30*20)` = **18 → Risk Low**
- **Criticality:** Flag B Layer 1 fires — `marketId` removed + `mktId` added in a consumed
  `.avsc` = contract break → **High**
- **Cell:** Risk Low + Crit High → **1–2 reviews**

```
PR: Risk Low, Criticality High → 1–2 reviews. 1 reviewer (+ schema owner if it touches something sensitive).
```

A pure line-count score would call this trivial and wave it through. The OR flag catches that
a "rename" is a breaking change for everyone downstream.
