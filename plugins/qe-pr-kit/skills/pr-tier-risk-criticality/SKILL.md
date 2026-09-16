---
name: pr-tier-risk-criticality
description: "Score a Pull Request on a 2×2 Risk × Criticality matrix and decide how much human review it needs — AI-only, 1 review, 1–2 reviews, or 2 reviews. Also bootstraps a service's critical-areas.yaml. Trigger whenever the user wants to assess a PR, asks 'how much review does this PR need', 'is this PR risky', 'which review tier', 'score this PR', 'should this be double-reviewed', pastes a diff or PR link and asks how to review it, or wants to set up / bootstrap the critical areas list for a service. Also trigger for: 'avalia este PR', 'quanto review precisa este PR', 'este PR é arriscado', 'que tier de review', 'classifica este PR', 'precisa de review duplo', 'cria a lista de áreas críticas', 'bootstrap das zonas críticas'. Prefer triggering over not — if there's any chance the user wants a review-tier decision for a PR, or wants to define critical areas, activate this skill."
---

# PR tier — Risk × Criticality

Decide how much human review a Pull Request needs by answering two independent questions and
crossing them in a 2×2 matrix. **A person always performs the merge. Never merge, and never
write code.**

Two modes:

- **Score mode** (default) — a PR or diff exists; classify it and output the tier.
- **Bootstrap mode** — no `critical-areas.yaml` yet, or the user asks to create or refresh
  it; propose the list for a human to curate.

You run **in the caller's context**, so the diff and your working lands in their
conversation. That is often what they want — they are here to look at the change and talk
about it. When the verdict alone is wanted, and the diff should stay out of the way, dispatch
the `pr-tier-risk-criticality` **agent** instead; it gives the same answer in isolation.

---

## Locate the model

Resolve the kit root:

```bash
echo "${CLAUDE_PLUGIN_ROOT}"
```

If it prints nothing, `Glob` for `**/references/tiering-model.md`.

**Read `references/tiering-model.md` before scoring anything.** It holds the axes, the
weights, the thresholds, the criticality flags, the matrix and the output format — the single
source of truth this skill and the agent both follow. Do not score from memory, and never
keep a second copy of those rules in this file.

---

## Score mode

**1. Gather the change.** With git access: `git diff <base>...<head>`, plus `git log` on the
touched files for the hotspot signal. Otherwise use the diff the user pasted; if you have
only a link you cannot fetch, ask for the diff rather than guessing. Locate
`critical-areas.yaml` (repo root or `.github/`) — if it is absent, offer bootstrap mode, then
score with the remaining criticality flags and say the file was missing.

State assumptions instead of asking questions you can answer yourself.

**2. Score both axes** exactly as `tiering-model.md` specifies.

**3. Run the judge.** If the deterministic `Missing tests` value is **below 70** and the
`Agent` tool is available, dispatch `pr-tier-test-judge` with three things and nothing else:
the production diff, the test diff, and the absolute path to `references/test-quality/`.

Withhold the tier, the other signals and the criticality verdict. A judge that knows what its
answer costs is no longer independent.

Apply the returned band as `tiering-model.md` specifies. **If the `Agent` tool is not
available, do not pretend the judge ran** — use the deterministic value and report
`Missing tests = deterministic check only, judge unavailable`.

**4. Report.** One line for the tier. A second line only if the judge penalised. Expand into
the signal breakdown only when asked why.

---

## Bootstrap mode

Trigger when there is no `critical-areas.yaml`, or the user asks to create or refresh it. You
**propose**; a human curates and commits it through a normal PR. **Do not commit it
yourself.**

**1. Scan three sources.**

- **Directory scan** → candidate sensitive paths: folders named `auth`, `payments`,
  `migrations`, `statemachine`, `settlement`, feature-flag definitions.
- **Git history** → hotspots: high churn plus frequent fix or revert commits. Cross-reference
  linked bug tickets where available.
- **Service catalog** (`service.datadog.yaml` / Compass, if present) → which paths are public
  contract surface, and the owning team as a starting draft for `owner`.

**2. Apply the criticality criterion.** Keep a candidate **only if** at least one holds — the
same OR logic as Flag A in `tiering-model.md`:

- **Already happened?** A real past incident linked to this area. The strongest signal.
- **Does anyone outside depend on it?** A contract — API or event — another service consumes.
- **Can it be undone?** If not (migration, destructive delete, money already paid) → critical.

If none hold, **drop it.** Resist inflating the list: a bloated file routes everything to
heavy review and defeats the purpose.

**3. Emit YAML** for the user to review and commit.

```yaml
critical_areas:
  - path: "src/statemachine/**"          # glob; ** matches everything under the folder
    category: [state_machine]            # state_machine | money | public_contract | irreversible | customer_facing
    reason: "hotspot: 4 fix commits in last 60 days"   # short, human-checkable
    owner: grizzlies                     # team (most common) | person handle | null
```

Every entry needs a justification a human can check. Leave `owner: null` where unknown.

**4. Drift check (optional, recurring).** Re-running bootstrap later flags new sensitive paths
that appeared since the file was written. Report additions as suggestions; never edit the
committed file yourself.

---

## Hard rules

1. **Never merge. Never edit or write code.** Advisory output only.
2. **Read the model from `tiering-model.md`.** Never reproduce the weights, thresholds or
   flags here — they live in one file so this skill and the agent cannot diverge.
3. **The judge sees the two diffs and the rulers path. Nothing else.**
4. **The judge is penalty-only.** It never lowers `Missing tests`.
5. **If the judge could not run, say so.** Never issue a tier as though it had.
6. **Bootstrap proposes; a human commits.** No strong reason, no entry.
