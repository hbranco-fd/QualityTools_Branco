---
name: cucumber-component-test-writer
description: Define component-level test plans in Cucumber/Gherkin, in business language (EVC style), for any service or flow — not just PCSA-MD. Trigger on "component tests", "testes de componente", "component test plan", "cucumber component tests", "write component tests for X", or when the user wants a Gherkin `.feature` file paired with a Confluence component-test page and a Mock Inventory. Distinct from a low-level functional/technical test plan (topic aliases, JSONPath inline in steps) — this skill writes steps as business behaviour, pushing all technical detail (payload paths, JSONPath, topic names) into mocks and a Mock Inventory table, never inline in Given/When/Then. Prefer triggering over not — if there's any chance the user wants component-level Gherkin scenarios with this style, activate.
---

# Cucumber Component Test Writer

Produces a component-level test plan as Gherkin (Cucumber) scenarios, written in **business language** — Given/When/Then describe behaviour, not mechanics. Technical detail (payload file paths, JSONPath expressions, topic/queue names) lives only in mocks and the Mock Inventory, never inline in a step.

This is the counterpart to a low-level functional test plan skill (e.g. one that writes steps like `Given "Kafka" payload with headers is set to "domain/gma/market/X.json"`). Use **this** skill when the user wants component tests that read like a spec a non-engineer could follow. Use the other one when the user explicitly wants wire-level Kafka/topic mechanics in the steps themselves.

---

## When to use this vs. a technical functional test plan

| Signal | Use this skill (business language) | Use technical/functional skill |
|---|---|---|
| "component tests", "component test plan" | ✅ | |
| User pastes a `.feature` full of `Kafka message ... published to "X_INPUT" topic` and wants more like it | | ✅ |
| User wants a Confluence page a business stakeholder can read | ✅ | |
| User explicitly asks for topic names / JSONPath in the steps | | ✅ |

If unclear, ask once: "Estilo negócio (Given/When/Then sem detalhes técnicos, tipo EVC) ou estilo técnico (com topics/JSONPath inline)?"

---

## Workflow

Always aim for **high coverage** — every meaningful happy/unhappy/edge case for the feature. High coverage does not mean padding: skip anything that doesn't add new information (see "Avoiding redundancy" below).

### Step 1 — Understand the feature

Read whatever source is available: user story, ticket, acceptance criteria, source code, or the user's own description. Extract:
- The **triggers** (what inputs/events cause behaviour)
- The **entities** involved
- The **expected observable outputs** (published message, API response, state change)
- Any **rejection/blocking conditions**

If a rule is derived from a combination of inputs (e.g. handicap vs non-handicap, sport type), note it — it becomes a `Scenario Outline` with `Examples`, not repeated scenarios.

Flag ambiguous or unverifiable scenarios explicitly rather than guessing (e.g. "this scenario isn't observable in the current environment because X blocks it upstream" — remove it rather than write a test that can't pass).

### Step 2 — Identify scenarios (single flat list, no groups)

Do not split the feature into sub-groups/sections. All scenarios for the feature live in one flat, sequentially numbered list, ordered logically (happy paths first, then unhappy, then edge/cross-cutting) — not bucketed under headings.

**Happy paths (always):**
- Full flow end-to-end producing the correct output
- One scenario per meaningful input variant

**Unhappy / edge (always):**
- Rejected/invalid input → no output or explicit rejection
- Blocked transition (state doesn't allow the action)
- Missing optional field → correct fallback behaviour
- Idempotency: same trigger twice → second produces no new output

**Cross-cutting (always, if applicable to the feature):**
- Partial data (one of several related fields present, others absent)
- Ordering/race conditions if the flow is async
- Downstream propagation if the output must also be verified in another service

**Scenario ID convention:** `CT-<NN>`, sequential across the whole feature (`CT-01`, `CT-02`, ...). No group codes, no restarting the count.

Use `Scenario Outline` + `Examples` when the same behaviour repeats across a closed set of variants (e.g. market sort types, sport types) — don't write out N near-identical scenarios; that's redundant, not high coverage.

### Avoiding redundancy

High coverage means every case that can produce a *different* observable outcome — not every permutation. Before adding a scenario, check:
- Does it exercise a rule/branch not already covered by another scenario? If not, drop it.
- Can it be folded into an existing `Scenario Outline` as another `Examples` row instead of a new scenario? Prefer that.
- Is it the same case with cosmetic differences (different ID, same field, same value type)? Drop it.
- **Is this just a new field on an already-covered flow?** If the feature under test only adds a field to entities/payloads that existing scenarios already exercise, and the flow/trigger/outcome don't change, don't write a new scenario. Instead: add the field to the relevant existing mocks (⚠️ in the Mock Inventory, Step 5), assert the new field where the existing scenario already asserts other output fields, and note in the Mock Inventory row which existing scenario ID(s) it applies to. Only write a genuinely new scenario if the field introduces a new branch (e.g. absence of the field changes behaviour, or the field has multiple values with different expected outcomes) — that new branch does get its own `CT-<NN>` (or an `Examples` row).

### Step 3 — Write the `.feature` file (business language)

**Rules:**
- Given/When/Then describe **what happens in the domain**, not the transport. No payload file paths, no topic names, no JSONPath in the step text.
  - ❌ `Given "Kafka" payload with headers is set to "domain/fip/market/Win.json"`
  - ✅ `Given a non-handicap market that has not yet been resulted`
- Technical wiring (which payload, which topic, which JSONPath) is implementation detail — it goes in the **Mock Inventory** (Step 5) and in the automation code, never in the feature file text.
- **Every scenario name starts with its ID** — `Scenario: CT-01 — <description>` — never a bare description without the ID. This is how the scenario is referenced everywhere else (table, Mock Inventory, Implementation Spec).
- One `Feature`, one flat sequential list of scenarios — no sub-headings, no per-group sections.
- Each scenario independently runnable; use `Background` only for setup shared by every scenario in the file.
- Comment (`#`) any non-obvious business rule so the reader understands *why*, not just *what*.

```gherkin
Feature: <Business capability being tested>

  Background:
    Given <minimum shared setup, in business terms>

  Scenario: CT-01 — <happy path, plain description>
    Given <precondition>
    When <trigger, business terms>
    Then <observable outcome>

  Scenario: CT-02 — <unhappy path>
    Given <precondition>
    When <invalid/blocked trigger>
    Then <no output / rejection, stated in business terms>

  Scenario Outline: CT-03 — <behaviour that repeats across variants>
    Given a "<variant>" <entity>
    When <trigger>
    Then <outcome>

    Examples:
      | variant |
      | A       |
      | B       |

  Scenario: CT-04 — <next case, numbering keeps going>
    ...
```

### Step 4 — Produce the Confluence component-test page

Structure — **one flat table, no per-group sections**:

```
## Introduction
Purpose: component-level test plan for <feature>.
Scope: <what's covered> / Out of scope: <what isn't, and why>.

## Scenarios
| ID | Status | Entity | Field | Steps | Expected Result | Result Obtained |
(One row per scenario, ID matches the .feature scenario name exactly, e.g. CT-01)
(Steps column = plain-language summary of Given/When/Then, not the raw Gherkin)
(Result Obtained always left empty — filled during execution)

## Feature file
[full .feature code block, all scenarios, in the same order as the table]
```

If a scenario turns out not to be observable/testable in the real environment (upstream blocks it, feature flag disabled, etc.), remove it from both the table and the `.feature` file rather than leaving a test that can never pass — note why in a short remark in the Introduction.

### Step 5 — Mock Inventory (always include)

Every component test has payload/mock dependencies even though the feature file itself doesn't mention them. List them separately:

```
## Mock Inventory
| File path | Status | Action required |
|---|---|---|
| path/to/payload.json | ❌ Missing | Create — minimum fields: ... |
| path/to/existing.json | ✅ Exists | Reuse as-is |
| path/to/existing2.json | ⚠️ Needs change | Add field X (applies to CT-02, CT-05) — no new scenario needed, same flow/outcome |
```

Always check the repo's existing test resources before marking something missing.

### Step 6 — Implementation Spec (offer, don't force)

If the user wants this handed off for automation, offer a companion page/section:
- Sequential numbered tasks (one per scenario, same order as the `.feature` file), each with a checkbox
- Suggested commit message per task
- Order tasks so shared setup/step definitions come first

Ask: "Queres também a Implementation Spec para automação, ou só o `.feature` + página chega?"

---

## Confluence notes

- Use **HTML** for `updateConfluencePage`/`createConfluencePage` — not markdown.
- `updateConfluencePage` needs the **full page body** every time (no partial append) — fetch current content first if editing.
- Tiny link IDs from `/wiki/x/...` URLs work directly as `pageId` — no need to decode.
- Place the new page under the relevant test-plan hub page.

---

## Common mistakes

| Mistake | Fix |
|---|---|
| Payload paths / topic names / JSONPath inline in Given/When/Then | Move to Mock Inventory + automation code; steps stay business-language |
| Only happy paths | Always add unhappy + idempotency + blocked-transition cases |
| Splitting scenarios into groups/sections | One flat sequential list, `CT-01`, `CT-02`, ... — no sections |
| Scenario name without its ID | Every `Scenario:`/`Scenario Outline:` name starts with `CT-<NN> — ` |
| Repeating near-identical scenarios for each variant | Use `Scenario Outline` + `Examples` instead |
| Adding scenarios that don't test a new rule/branch | Drop it — high coverage means distinct outcomes, not permutations |
| Writing a whole new scenario just to cover a new field on an already-tested flow | Add the field to the existing mock (⚠️ in Mock Inventory), assert it in the existing scenario — only new branch/value gets a new `CT-<NN>` |
| Writing a scenario for behaviour that can't actually occur in the environment | Verify against upstream/blocking logic first; drop or flag it |
| Leaving Mock Inventory empty | Every feature file has at least one mock dependency — list it |
| Filling in "Result Obtained" | Leave empty — that's filled during execution, not planning |
