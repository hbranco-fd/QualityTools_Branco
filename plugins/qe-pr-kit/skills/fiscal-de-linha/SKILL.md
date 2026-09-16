---
name: fiscal-de-linha
description: "Fiscal de Linha — score a Pull Request on a 2×2 Risk × Criticality matrix and decide how much human review it needs — AI-only, 1 review, 1–2 reviews, or 2 reviews. Also bootstraps a service's critical-areas.yaml on first run. Trigger whenever the user invokes 'Fiscal de Linha', wants to assess a PR, asks 'how much review does this PR need', 'is this PR risky', 'which review tier', 'score this PR', 'should this be double-reviewed', pastes a diff/PR link and asks how to review it, or wants to set up / bootstrap the critical areas list for a service. Also trigger for: 'fiscal de linha', 'avalia este PR', 'quanto review precisa este PR', 'este PR é arriscado', 'que tier de review', 'classifica este PR', 'precisa de review duplo', 'cria a lista de áreas críticas', 'bootstrap das zonas críticas'. Prefer triggering over not — if there's any chance the user wants a review-tier decision for a PR, or wants to define/bootstrap critical areas, activate this skill."
---

# Fiscal de Linha — PR Review Tiering (Risk × Criticality Matrix)

**Fiscal de Linha** ("linesman") checks every play before it counts: it decides how much human review a Pull Request needs by answering two independent questions and crossing them in a 2×2 matrix. It flags the call — **a person always performs the merge. The agent never merges and never writes code.**

Reference design (full rationale): Confluence "PR Review Tiering Agent — Risk × Criticality Matrix" (page 311876551539, SBK space).

This skill has **two modes**:
- **Score mode** (default) — a PR/diff exists; classify it and output the tier.
- **Bootstrap mode** — no `critical-areas.yaml` yet (or user asks to create/refresh it); propose the critical-areas list for the service.

---

## The core model (do not deviate)

Two **independent** axes. Never mix them into a single score.

| | Risk Low | Risk High |
|---|---|---|
| **Criticality High** | 1–2 reviews | 2 reviews |
| **Criticality Low** | AI-only | 1 review |

- **Risk** = probability this PR introduces a bug. Computed by a **weighted sum** → threshold.
- **Criticality** = severity of the damage if a bug ships. Computed by an **OR of flags** → any hit = High.

Criticality **dominates**: if Criticality is High, the PR can never land in AI-only, even with Risk Low.

---

## Score mode — how to produce the tier

### Step 0 — Gather the diff

You need the actual change. In order of preference:
1. If running with git access: `git diff <base>...<head>` (or the PR's diff). Also get `git log` for touched files (hotspot signal).
2. If the user pasted a diff or PR link: use that. If only a link and you can't fetch it, ask them to paste the diff.
3. Locate the service's `critical-areas.yaml` (repo root or `.github/`). If absent → offer Bootstrap mode first, then fall back to universal criticality signals only.

State any assumption you make instead of asking unnecessary questions.

### Step 1 — Axis 1: Risk (weighted sum → threshold)

Three signals. Score each 0–100, then combine with weights. **Do the arithmetic yourself and show it** — this axis must be reproducible and transparent.

| Signal | Weight | How to score it (0–100) |
|---|---|---|
| Change size | 35 | Files + lines changed. **Exclude auto-generated files** (lockfiles, codemods, mass renames, generated clients). Rough guide: ≤2 files / ≤50 lines → ~10-20; several files / moderate lines → ~40-60; many files / large diff → ~80-100. Weight files more than lines. |
| Missing tests | 35 | Do the **new or changed lines** have test coverage in this same PR? Fully covered → ~0-10. Partially → ~40-60. New logic with no tests → ~90-100. **Only count coverage of changed lines**, never the whole file (avoids penalising legacy files unfairly). |
| File hotspot history | 30 | From `git log` on touched files: frequent recent fix/revert commits, or files linked to past bugs → high. No churn → ~0-20. Occasional fixes → ~40-60. Known hotspot / recent reverts → ~80-100. |

`risk_score = round(0.35*size + 0.35*tests + 0.30*hotspot)`

- **risk_score > 55** → **Risk High**
- **risk_score < 45** → **Risk Low**
- **45–55** → **uncertain**: do not auto-decide. Report both candidate tiers and flag for manual verification.

### Step 2 — Axis 2: Criticality (OR of flags → High)

**No arithmetic.** Check each flag as yes/no. **Any single hit → Criticality High.** Multiple weak reasons do not substitute for one strong reason.

Flag A — **Sensitive area hit.** Does any changed path match an entry in `critical-areas.yaml`? (Glob match on `path`.) If yes → High, and note the matched entry's `owner` and `reason`.

Flag B — **Incompatible contract break.** Two layers, run both:
- **Layer 1 (deterministic, no AI).** For contract files (`.avsc`, `.proto`, `openapi.yaml`, GraphQL SDL, Kafka schemas, etc.): diff old vs new. A field **removed or changed** (type change, tightened requirement, renamed) = break. A field/event **added** = compatible, NOT a break. Renaming a field in a consumed event = removed + added = break.
- **Layer 2 (semantic, you).** For breaks the diff can't see — meaning changed without format change, contract logic spread through normal code — read and judge. This is a second net, not the only one.
- Either layer firing → High.

Flag C — **Irreversible.** Migrations, destructive deletes, anything without an easy rollback → High.

Flag D — **Customer-facing + high availability.** Directly user-visible surface with strict SLA → High.

`criticality = High if (A or B or C or D) else Low`

### Step 3 — Cross the matrix → tier

Look up the cell. Output exactly one tier:

| Cell | Tier | What it means |
|---|---|---|
| Risk Low + Crit Low | **AI-only** | No human reviewer required; owner merges. |
| Risk High + Crit Low | **1 review** | One reviewer, no extra ceremony. |
| Risk Low + Crit High | **1–2 reviews** | One reviewer required; a second (the area `owner`) if the change touches something sensitive inside the zone. |
| Risk High + Crit High | **2 reviews** | Two reviewers incl. the area `owner`; QA signalled before merge. |

If Step 1 returned **uncertain**, report the two adjacent tiers and say a human must break the tie.

### Step 4 — Output

**Default: one line. Advisory only — no merge, no code edits.** Compute everything above internally, but report only the verdict. Do NOT dump the signal breakdown unless the user asks "why" / "porquê" / "mostra o detalhe".

**Clear case** (Risk decided):
```
PR: Risk <Low/High>, Criticality <Low/High> → <tier>. Reviewed by <who>.
```
- `<who>` = "AI only (owner merges)" for AI-only; "1 reviewer" for 1 review; "1 reviewer (+ <owner> if it touches something sensitive)" for 1–2 reviews; "2 reviewers incl. <owner>, QA signalled" for 2 reviews.

Examples:
```
PR: Risk Low, Criticality Low → AI-only. No human reviewer needed; owner merges.
PR: Risk High, Criticality Low → 1 review. Reviewed by 1 reviewer.
PR: Risk Low, Criticality High → 1–2 reviews. 1 reviewer (+ schema owner if it touches something sensitive).
PR: Risk High, Criticality High → 2 reviews. 2 reviewers incl. grizzlies, QA signalled before merge.
```

**Uncertain case** (Risk score in 45–55 band): don't pick. State the criticality (which is always decided), name the two candidate tiers, and hand the tie to the human:
```
PR: Criticality <Low/High>, Risk uncertain (score <n>, in the 45–55 band) → between <tier A> and <tier B>. I can't call it — please break the tie.
```

Example:
```
PR: Criticality Low, Risk uncertain (score 48, in the 45–55 band) → between AI-only and 1 review. I can't call it — please break the tie.
```

If the user then asks why, expand with the full breakdown:
```
Risk <Low/High> (score <n>/100): size <n>, tests <n>, hotspot <n>.
Criticality <Low/High>: sensitive area <hit/no>, contract break <hit/no>, irreversible <yes/no>, customer-facing <yes/no>.
```


---

## Bootstrap mode — propose critical-areas.yaml

Trigger when there's no `critical-areas.yaml`, or the user asks to create/refresh it. The agent **proposes**; a human curates and commits via a normal PR.

### Step B1 — Scan three sources

1. **Directory scan** → candidate sensitive paths: folders named `auth`, `payments`, `migrations`, `statemachine`, `settlement`, feature-flag defs, etc.
2. **Git history** → hotspot files: high churn + frequent fix/revert commits (cross-reference linked bug tickets if available).
3. **Service catalog** (Datadog `service.datadog.yaml` / Compass, if present) → which paths are public contract surface, and the owning team (starting draft for `owner`).

### Step B2 — Apply the criticality criterion

For each candidate, keep it **only if** at least one is true (the same OR logic as the axis):
- **Already happened?** Real past incident linked to this area (strongest signal).
- **Does anyone outside depend on it?** A contract (API/event) another service consumes.
- **Can it be undone?** If not (migration, destructive delete, money already paid) → critical.

If none hold, **drop it** — resist inflating the list. A bloated list routes everything to heavy review and defeats the purpose.

### Step B3 — Emit YAML

```yaml
critical_areas:
  - path: "src/statemachine/**"          # glob; ** matches everything under the folder
    category: [state_machine]            # state_machine | money | public_contract | irreversible | customer_facing
    reason: "hotspot: 4 fix commits in last 60 days"   # short human justification
    owner: grizzlies                     # team (most common) | person handle | null
```

Output as a file the user reviews and commits. **Do not commit it yourself.** Every entry needs a human-checkable `reason`; leave `owner: null` where unknown.

### Step B4 — Drift check (optional, recurring)

Re-running bootstrap later flags **drift**: new sensitive paths that appeared since the file was last written. Report additions as suggestions; never auto-edit the committed file.

---

## Hard rules (never break)

1. **Never merge. Never edit or write code.** Advisory output only.
2. **Two axes stay separate.** Risk is a weighted sum; Criticality is an OR of flags. Never collapse into one number.
3. **Criticality dominates.** Any criticality flag → never AI-only.
4. **Contract break = removed/changed field, not added.** Adding is compatible.
5. **Coverage counts changed lines only**, never the whole file.
6. **Change size excludes auto-generated files** (lockfiles, codemods, mass renames).
7. **Bootstrap proposes; a human commits.** Don't inflate the critical list — no strong reason, no entry.
8. Weights (35/35/30) and thresholds (50, band 45–55) are a starting point, not calibrated truth. If the user has calibration data, use it; otherwise state these are defaults.

---

## Worked example (score mode)

Input: PR renames `marketId` → `mktId` in a Kafka Avro schema consumed by the Hub, 3 files, has tests.

Internal computation:
- **Risk:** size ~25 (3 files, mechanical), tests ~10 (covered), hotspot ~20 → `round(.35*25 + .35*10 + .30*20)` = **18 → Risk Low**.
- **Criticality:** Flag B Layer 1 fires — `marketId` removed + `mktId` added in a consumed `.avsc` = **contract break → High**.
- **Cell:** Risk Low + Crit High → **1–2 reviews.**

Output (one line):
```
PR: Risk Low, Criticality High → 1–2 reviews. 1 reviewer (+ schema owner if it touches something sensitive).
```

**Why it matters:** a pure line-count score would call this trivial and wave it through. The OR flag catches that a "rename" is a breaking change for downstream consumers. If the user asks why, expand:
```
Risk Low (score 18/100): size 25, tests 10, hotspot 20.
Criticality High: contract break HIT (Layer 1) — field `marketId` removed from consumed Avro schema.
```
