---
name: manual-test-plan-writer
description: Use when defining manual test cases or a manual test plan for any service or feature — new fields, flag transitions, state machines, batch jobs, UI behaviour, API validation, or cross-service flows. Triggers on "define manual tests", "write manual test plan", "manual test cases for X", "testes manuais", "plano de testes manuais", "test plan for this feature", or when a Confluence manual test plan page needs to be created or updated.
---

# Manual Test Plan Writer

## Overview

Produces manual test plans focused on **critical coverage** — the fewest, highest-value scenarios. A manual plan is not a mirror of the automated suite; it targets the happy path, the common failures, and what automation can't easily reach.

## Workflow

Do not jump straight to tables. Every time:

1. **Read the source** — acceptance criteria, spec, state diagram, or ticket.
2. **Extract the rules** — what inputs, triggers, and conditions determine each outcome. Write these first; they drive everything.
3. **Define groups** — by *what triggers the behaviour*, derived from the rules (see Grouping).
4. **Select scenarios** — happy path + common failures + one per group + edge cases where outputs diverge. Drop what automation covers trivially (see Coverage).
5. **Pick the format** — detailed, scenario-based, or validation-based (see Table Formats).
6. **Write the cases** — numbered steps, one action per line, right tool, exact expected result.

## Principles

- **Critical over exhaustive.** 8 well-chosen cases beat 40 that duplicate automation.
- **The feature drives the structure.** Groups, IDs, and columns derive from what's tested — never a fixed skeleton.
- **Assert on observable outputs.** Published messages, API responses, UI, persisted data — not internal state a tester can't see.
- **Isolate the variable.** Each case changes one thing. If two outputs can move independently, test the case where they diverge.

---

## Grouping

Group by **what triggers the behaviour**, derived from the rules in step 2. No fixed set — ask: what are the distinct triggers? which inputs produce *different* outcomes? what are the edge combinations?

Illustrative shapes (derive your own, don't copy):

| Feature type | Groups might be |
|---|---|
| Field derived from multiple inputs | One per input source; one for update transitions; one for edge combinations |
| Batch / background job | Job triggers; processes data correctly; handles edge cases (empty, future-dated, duplicate) |
| UI feature | Display per level; override mechanics (lock/update/reset); inheritance |
| API contract | Happy path per operation; validation/error cases; boundary values |
| State machine | One per transition; one for invalid/blocked transitions |

---

## Coverage Selection

**Always include:**
- **The happy path** — the primary success scenario the feature exists to deliver. Every plan must have at least one, even if automation covers it, because it's the baseline sanity check for the environment.
- **Common failure scenarios** — the most likely ways the feature breaks in practice: invalid input, missing/empty data, wrong state, blocked/rejected operations, boundary values. Pick the handful most likely to occur, not every theoretical failure.

**Also include:**
- One representative scenario per behaviour group
- Every edge case where two outputs can diverge (e.g. one flag true while a related flag is false)
- High-risk or historically buggy paths
- Cross-service scenarios where the output propagates and must be verified downstream

**Exclude:**
- Redundant permutations that add no new information
- Internal state not observable to the tester
- Exhaustive failure combinations already covered trivially by automation (keep only the common, high-value ones)

---

## Table Formats

Pick the shape that fits the feature. Three common ones:

### 1. Detailed (step-by-step execution)
Best for behaviour that needs a precise sequence and per-field assertions.

| ID | Entity | Field | Steps | Expected Result | Result Obtained |

- **Entity** and **Field** are *domain-specific columns* — adapt them. If the feature isn't about entities/fields, replace with what's relevant (e.g. `Endpoint`, `Component`, `Job`) or drop them.

### 2. Scenario-based (concise)
Best for many small variations of the same behaviour.

| ID | Scenario | Pre-condition | Expected result |

### 3. Validation-based (E2E / integration)
Best for exploratory or cross-service flows where each row is a checklist.

| ID | Validations | Evidences / Notes | QA |

**Always leave the results/evidence column empty** — it's filled during execution.

---

## Test Case Anatomy

### ID — reflects what's tested
Never a generic `TC-`. Use a prefix derived from the feature or group.

- **Format:** `[PREFIX]-[NN]`, uppercase, prefix ≤ ~8 chars
- **Derive the prefix from** the feature (`ISOFF-01`), the group behaviour (`CREATE-01`, `UPDATE-01`, `BATCH-01`), or service + area (`PCSS-BATCH-01`)
- **Reset numbering per group** (group 1 → `01`, group 2 → `01`)
- **Be consistent** within a page

### Steps — numbered, one action per line
- Start with the pre-conditions (what must exist before the test runs)
- Name the tool, field, value, and time window ("1–2 minutes in the future") — specific enough for a tester with no context
- Verify on whatever surface the tester can observe
- Where relevant, end with a guard: "Confirm no further/unexpected changes occur."

### Expected Result — exact, not vague
State the outcome and the trigger. Good: "After the update, X = <value>, Y unchanged." Bad: "Verify the output is correct."

---

## Reusable Step Patterns

Fill in the tool, field, and value per feature:

```
Ensure [required setup / hierarchy] exists.
Using [tool], create [entity] with [field = value], [field = value].
Check [output surface] and confirm [field = expected].
Wait until [condition / scheduled time] is reached.
Using [tool], update [field] to [value].
Check [output surface] and confirm [field = expected], [other field unchanged].
Confirm no further/unexpected changes occur.
```

---

## When the Behaviour Is Rule-Derived

If the output derives from a combination of inputs, put a **rules table** in the Introduction so expected results are unambiguous — one row per input combination → expected output. This anchors every case's Expected Result to a documented rule.

| Input condition(s) | Expected output(s) |
|---|---|
| condition A | output X |
| condition A + edge modifier | output Z |

---

## FanDuel Context (adapt per service)

These are the tools and conventions common in FanDuel QA. Use whichever fit; a given plan usually needs only a few.

| Tool | Used for |
|---|---|
| MPM | Entity creation / field updates via UI |
| GPD payload (manual) | Creating entities with fields the UI doesn't expose |
| Kafka consumer | Verifying published output (field values on the topic) |
| JMX | Triggering batch jobs / scheduler operations |
| GraphQL / REST API | Direct API validation (e.g. GMA, PCC, PCH) |
| Hawtio / actor state | Internal service state inspection |
| Elasticsearch | Verifying persisted values |
| PCUI / HUB | UI field display, overrides, inheritance |

Common environments: INTSS, DEV-USE1, INTBS1 — state which one the plan targets.

Common Market Data hierarchy (when relevant): Superclass → Subclass → Event Type → Market Type Link → Event → Market → Selection. A frequent pre-condition is "Ensure the full upper hierarchy exists."

---

## Confluence Page Notes

- Use **HTML** format for `updateConfluencePage` (not markdown)
- Numbered steps → `<ol><li>...</li></ol>`
- Field/value tokens → `<code>` tags
- Leave the results/evidence column empty
- `updateConfluencePage` requires the full body (no partial append); fetch current version before updating
- Place under the relevant hub page for the feature

---

## Common Mistakes

| Mistake | Fix |
|---|---|
| No happy path in the plan | Always include the primary success scenario as a baseline |
| Only testing success | Add the common failure cases (invalid input, empty data, blocked ops) |
| Generic `TC-01` IDs | Use a feature/group prefix (`ISOFF-01`, `BATCH-01`) |
| Imposing a fixed set of groups | Derive groups from the acceptance criteria |
| One tool for everything | Match the tool to the flow (API, batch, UI, messaging) |
| Mirroring the entire automated suite | Cut to critical paths — one per group + edge cases |
| Vague expected result | State exact values and the trigger condition |
| Steps not numbered / multi-action lines | Number them, one action per line |
| Asserting on unobservable internal state | Assert on outputs the tester can see |
| Forcing Entity/Field columns when they don't fit | Use the table format that matches the feature |
