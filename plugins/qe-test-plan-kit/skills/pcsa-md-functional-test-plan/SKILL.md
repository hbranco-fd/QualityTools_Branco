---
name: pcsa-md-functional-test-plan
description: Generate a functional test plan for PCSA-MD features as Gherkin scenarios (.feature file drafts) ready for implementation or use as a spec. Trigger whenever the user mentions: test plan, functional tests, Gherkin scenarios, feature file, BDD scenarios, test coverage, "what should we test", "write tests for", or names a specific PCSA-MD flow/entity (GTH, FIP, GMA, eviction, result confirmation, cross-entity validation, subscription, inheritance, JMX flush). Also trigger when the user shares a user story, Jira ticket, acceptance criteria, or any feature description for PCSA-MD and asks what to test or to derive test cases. Also trigger for: "testes funcionais", "plano de testes", "cenários de teste", "spec de testes", "o que testar para esta story", "deriva testes desta story". Prefer triggering over not triggering — if there's any chance the user wants test scenarios for PCSA-MD, activate this skill.
---

# PCSA-MD Functional Test Plan

Produces a functional test plan as Gherkin `.feature` file drafts for PCSA-MD — ready to implement in the `functional-tests-market` module or hand off as a spec.

This skill has **two input modes**:
- **Flow/entity mode** — user names a specific PCSA-MD flow, entity, or feed (e.g., "GTH Subclass creation", "GMA overrides on Market")
- **Story mode** — user pastes a user story, Jira ticket, or acceptance criteria and asks what to test

---

## Context: What you need to know about PCSA-MD tests

### Module structure

```
functional-tests-market/src/test/resources/features/
  domain/           ← MD domain tests (feed processing, overrides, JMX, eviction)
    feeds/
    overrides/
    jmx/
    eviction/
  stream/           ← MS stream tests (subscriptions, notifications, hierarchy)
    unsubscription/
    hierarchy/
    jmx/
```

### Domain entities and their feed sources

| Entity | Feed source | Input topic alias |
|---|---|---|
| Superclass / Subclass | GTH | `GTH_INPUT` |
| EventType / Event / Market | FIP | `FIP_INPUT` |
| All entities (overrides) | GMA/IPMA | `GMA_INPUT` |
| All entities (risk context) | PCSA-RD | `RD_INPUT` |
| Event / Market (eviction) | Eviction Stream | `EVICTION_INPUT` |

### Output topic aliases (sport-partitioned)

| Alias | Topic |
|---|---|
| `MD_OUTPUT_DELTA_FOOTBALL` | `catalog.market.domain.fd.football.delta` |
| `MD_OUTPUT_DELTA_TENNIS` | `catalog.market.domain.fd.tennis.delta` |
| `MD_OUTPUT_DELTA_RACING` | `catalog.market.domain.fd.racing.delta` |
| `MD_OUTPUT_DELTA_BASKETBALL` | `catalog.market.domain.fd.basketball.delta` |
| `MD_OUTPUT_DELTA_OTHERS` | `catalog.market.domain.fd.others.delta` |
| `MS_SUBSCRIPTIONS` | `pcsa.md.subscription.request` |
| `MS_NOTIFICATIONS` | `pcsa.md.subscription.notification` |
| `MS_OUTPUT_TOPIC` | MS stream output |

### Step vocabulary (use these patterns — don't invent new ones)

**Setup:**
```gherkin
* random UUID value is stored with index "correlationId"
* set property "correlationId" as SCENARIO_ID
* value "49" is stored with index "subclassId"        # football sportId
* store "EVENT_TYPE" default information
* store "MARKET_TYPE" default information
* store "EVENT" default information
* store "MARKET" default information
* store "SELECTION" default information
* "RANDOM" market with selections is created along with all hierarchy
* "RANDOM" upper hierarchy is created
* "TENNIS" type hierarchy from GTH is created on MD output
* "FOOTBALL" event is created along with all hierarchy on MD output
* unique long id is stored with index "subclassId"
```

**Action (feed publishing):**
```gherkin
Given "Kafka" payload with headers is set to "domain/gma/market/GMA_Override_Market_Name.json"
When Kafka message with key "marketId" is published to "GMA_INPUT" topic
When Kafka message with key "urn:sbk:pc:m:gpd:marketId" is published to "MD_OUTPUT_DELTA_TENNIS" topic
And SEP message for "MARKET" with key "rampIdMarket" containing the OpenBetId is published
And SEP message for "EVENT" with key "rampIdEvent" containing the OpenBetId is published
```

**State mutation:**
```gherkin
* value "CLOSE" is stored with index "action"
* value "REFRESH" is stored with index "action"
* value "NEW_MARKET_NAME" is stored with index "overrideValue"
* value "LOCK" is stored with index "overrideAction"
* value "ALL" is stored with index "instance"
```

**Assertions:**
```gherkin
Then consume "1" Kafka messages from "MS_SUBSCRIPTIONS" topic
Then consume "2" Kafka messages from "MS_OUTPUT_TOPIC" topic
Then "MD_OUTPUT_DELTA_OTHERS" should have no new messages
Then "MS_NOTIFICATIONS" should have no new messages
And "Kafka" response matches
  | $.subscribe.subscriberGBPId | urn:sbk:pc:e:gpd:eventId      |
  | $.subscribe.subscribable    | urn:sbk:pc:et:gpd:eventTypeId |
When Kafka message with value "urn:sbk:pc:e:gpd:eventId" for path "$.unsubscribe.subscribable" is picked
```

### Tags convention

```gherkin
@MD @<FeatureArea> @<EntityType>
# Examples:
@MD @GMAOverrides @Market
@MD @FIPFeed @Event
@MD @Eviction @Market
@HierarchyFlow
@MSStreamDeltas @MSUnsubscription
```

---

## How to produce the test plan

### Step 0 — Clarify scope before anything else

Before reading any code or writing any scenarios, ask the user ONE question:

```
Queres focar nos casos mais críticos (happy path + principais unhappy paths, cobertura mínima viável)
ou alta cobertura (todos os casos identificáveis: happy, unhappy, edge, idempotency, inheritance, sport routing, eviction)?
  A) Críticos — rápido, cobre os riscos principais
  B) Alta cobertura — exaustivo, todos os casos
```

Adapt scenario depth in Steps 3–4 based on the answer:
- **A (critical)**: happy path + top 2-3 rejection/unhappy paths only. Skip idempotency, inheritance, sport routing unless directly relevant to the feature.
- **B (high coverage)**: full checklist — happy, all unhappy paths, idempotency, inheritance, sport routing, eviction, edge cases.

Do not ask if the user already stated a preference in their message (e.g., "casos críticos", "alta cobertura", "tudo").

---

### Step 1 — Understand the feature

#### Mode A — Flow/entity input

If the user names a specific feature, flow, or entity (e.g., "resultConfirmed", "GTH Subclass creation", "eviction", "cross-entity validation"), read the relevant source files to understand the actual behaviour:
- Flow docs: `docs/flows/md/`
- Actor state: `apps/md/src/main/scala/.../domain/state/`
- Post-processors: `apps/md/src/main/scala/.../deltaapplier/postprocessor/`
- Adapter: `apps/md/src/main/scala/.../adapter/`

Extract: happy path behaviour, rejection conditions, edge cases visible from the types and config.

If the user describes the feature in their own words, use that as the source of truth.

#### Mode B — Story/ticket input

If the user provides a user story, Jira ticket, acceptance criteria, or any feature description, apply this analysis before writing any scenarios:

**1. Parse the story**
- Extract the actor, goal, and benefit from the story format ("As a... I want to... So that...")
- Extract all acceptance criteria (ACs) — list them explicitly
- If ACs are missing or vague, flag the gaps and state your assumptions

**2. Map to PCSA-MD flows**
For each AC, identify:
- Which entity/entities are affected (Superclass, Subclass, EventType, MarketType, Event, Market)
- Which feed triggers the change (GTH, FIP, GMA, RD, Eviction)
- What the expected output is (delta on which topic, or no output)
- Whether it touches MD domain, MS stream, or both

**3. Derive test scenarios from ACs**
Each AC maps to at least one scenario. Apply the standard scenario checklist (happy, rejection, idempotency, inheritance, sport routing, eviction) — but **only include types that are relevant to the story**. Skip types that are out of scope for the specific AC; don't pad with generic scenarios.

**4. Output a Story Coverage Table before writing the feature file**

```
Story: <title>

| AC | Entity | Feed/Trigger | Test type | Scenario title |
|---|---|---|---|---|
| AC1: ... | Market | FIP_INPUT | happy | Market created with correct name |
| AC1: ... | Market | FIP_INPUT | rejection | Market with missing mandatory field rejected |
| AC2: ... | Event | GMA_INPUT | happy | Event name override applied |
...

Gaps / assumptions:
- AC3 is ambiguous about sport routing — assuming football only
- No AC covers eviction — excluding eviction scenarios
```

Show this table to the user and confirm: "Cobre todos os ACs? Algum cenário em falta ou fora de âmbito?"

Only proceed to write the `.feature` file after confirmation (or if user says to proceed directly).

### Step 2 — Determine output placement

| Feature area | Folder |
|---|---|
| Feed processing (GTH, FIP, RD) | `domain/feeds/<entity>/` |
| GMA/IPMA overrides | `domain/overrides/<entity>/` |
| JMX operations (flush, get) | `domain/jmx/<operation>/` |
| Eviction | `domain/eviction/<entity>/` |
| MS stream / subscriptions | `stream/<topic>/` |
| Hierarchy / ordering | `stream/hierarchy/` |

### Step 3 — Identify scenarios

**Always include both happy paths AND unhappy paths.** A test plan with only happy paths is incomplete — unhappy paths are not optional.

#### Happy paths (always required)
- Full flow end-to-end: entity created/updated, correct delta published to correct topic
- Each valid variant of the feature (e.g., each resultType value, each override action type)

#### Unhappy paths (always required)
- **Rejection** — invalid/missing mandatory field → command rejected, no output published
- **Unknown entity** — feed message references an entity that doesn't exist in state → no output or explicit rejection
- **Out-of-order message** — message arrives before parent entity exists → no output or queued behaviour
- **Malformed payload** — structurally invalid message → no crash, no output
- Any feature-specific rejections visible from `CommandValidator` or actor state conditions

#### Additional (scope-dependent — include if mode B or if directly relevant)
- **Idempotency** — same command twice, second produces no delta
- **Inheritance** — parent changes → child entity updates
- **Sport routing** — correct output topic based on sportId (football/tennis/racing/basketball/others)
- **Eviction** — entity CLOSE/REMOVE, topic receives final delta or silence
- **Edge cases** — boundary values, optional fields absent, special enum values (e.g., HANDICAP)

Add entity-specific scenarios based on what you find in the code (e.g., for resultConfirmed: WIN → confirmed, NOT_DEFINED → not confirmed, HANDICAP special case).

### Step 4 — Write the `.feature` file

Follow this structure exactly:

```gherkin
@MD @<FeatureArea> @<EntityType>
Feature: <Short description of what is being tested>

  Background:
    * random UUID value is stored with index "correlationId"
    * set property "correlationId" as SCENARIO_ID
    * <minimum setup to make scenarios independent>

  Scenario: <Happy path — entity created and published to correct topic>
    # Setup specific to this scenario
    Given "Kafka" payload with headers is set to "<path/to/payload.json>"
    When Kafka message with key "<entityUrn>" is published to "<INPUT_TOPIC>" topic
    Then consume "1" Kafka messages from "<OUTPUT_TOPIC>" topic
    And "Kafka" response matches
      | <jsonPath> | <expectedValue> |

  Scenario: <Rejection — command rejected, no output>
    Given "Kafka" payload with headers is set to "<path/to/invalid_payload.json>"
    When Kafka message with key "<entityUrn>" is published to "<INPUT_TOPIC>" topic
    Then "<OUTPUT_TOPIC>" should have no new messages

  Scenario: <Edge case or entity-specific behaviour>
    # ...
```

**Rules:**
- Each scenario must be independently runnable (Background handles shared setup)
- Use existing step vocabulary — don't invent new steps unless you note they need implementation
- Payload file paths are placeholders — flag them as `TODO: create payload file`
- If a step doesn't exist in the vocabulary, add a comment: `# TODO: new step — implement in step definitions`
- Keep scenarios focused: one behaviour per scenario
- Add comments (`#`) to explain non-obvious intent

### Step 5 — Produce the output

**Always produce three things:**

1. **The `.feature` file draft** — saved to the correct `domain/` or `stream/` subfolder under `functional-tests-market/src/test/resources/features/`. Name: `<Source>_<Entity>_<Area>.feature` (e.g., `FIP_Market_ResultConfirm.feature`)

2. **A short test plan summary** — inline in chat, listing:
   - Feature area and entity
   - Scenarios identified (name + type: happy/unhappy/edge) — always both happy and unhappy
   - Coverage mode applied (critical / high coverage)
   - Payload files needed (TODOs)
   - New step definitions needed (TODOs)
   - Implementation notes (any complex setup or assertions that need clarification)

3. **Mock inventory** — always include a dedicated section listing every mock/payload file affected by this test plan:

```
## Mock Inventory

| File path | Status | Action required |
|---|---|---|
| domain/fip/market/FIP_Market_Win.json | ❌ Missing | Create — minimal FIP market payload with resultType=WIN |
| domain/fip/market/FIP_Market_NotDefined.json | ❌ Missing | Create — FIP market payload with resultType=NOT_DEFINED |
| domain/gma/market/GMA_Override_Market_Name.json | ✅ Exists | Reuse as-is |
| domain/gma/market/GMA_Override_Market_Name_Invalid.json | ⚠️ Needs change | Add missing mandatory field to trigger rejection |
```

Rules for mock inventory:
- **Always check** `functional-tests-market/src/test/resources/` for existing payload files before marking as missing
- Mark existing files that need modification as ⚠️ — describe exactly what needs to change and why
- For missing files, describe the minimum fields required for the scenario to work
- Never leave the mock inventory empty — every `.feature` file has at least 1 payload dependency

Then ask: "Queres que publique no Confluence como spec, ou o ficheiro `.feature` é suficiente?"

---

## Example output

For input: "testes para a resultConfirmed flow no FIP feed"

**Summary:**
```
Feature: FIP Market Result Confirmation (resultConfirmed)
Entity: Market
Folder: domain/feeds/market/
File: FIP_Market_ResultConfirm.feature

Scenarios:
  1. [happy] Market with WIN resultType → resultConfirmed = true published
  2. [happy] Market with LOSE resultType → resultConfirmed = true published
  3. [happy] Market with NOT_DEFINED resultType → resultConfirmed = false published
  4. [edge] HANDICAP market (awayHandicapScore set) → special resultType handling
  5. [idempotency] Same FIP message twice → second produces no delta

TODOs:
  - Payload files: domain/fip/market/FIP_Market_Win.json, FIP_Market_NotDefined.json, FIP_Market_Handicap.json
  - Verify: "MD_OUTPUT_DELTA_OTHERS" response matches resultConfirmed field path
```

**Draft `.feature`:**

```gherkin
@MD @FIPFeed @Market @ResultConfirmation
Feature: FIP Market Result Confirmation

  Background:
    * random UUID value is stored with index "correlationId"
    * set property "correlationId" as SCENARIO_ID
    * "RANDOM" market with selections is created along with all hierarchy

  Scenario: Market with WIN resultType publishes resultConfirmed=true
    Given "Kafka" payload with headers is set to "domain/fip/market/FIP_Market_Win.json"  # TODO: create payload
    When Kafka message with key "marketId" is published to "FIP_INPUT" topic
    Then consume "1" Kafka messages from "MD_OUTPUT_DELTA_OTHERS" topic
    And "Kafka" response matches
      | $.marketChanges[0].marketDefinition.resultType      | WIN  |
      | $.marketChanges[0].marketDefinition.resultConfirmed | true |

  Scenario: Market with NOT_DEFINED resultType publishes resultConfirmed=false
    Given "Kafka" payload with headers is set to "domain/fip/market/FIP_Market_NotDefined.json"  # TODO: create payload
    When Kafka message with key "marketId" is published to "FIP_INPUT" topic
    Then consume "1" Kafka messages from "MD_OUTPUT_DELTA_OTHERS" topic
    And "Kafka" response matches
      | $.marketChanges[0].marketDefinition.resultType      | NOT_DEFINED |
      | $.marketChanges[0].marketDefinition.resultConfirmed | false       |

  Scenario: HANDICAP market forces resultType override
    # awayHandicapScore or homeHandicapScore set at market level → resultType = HANDICAP
    * value "HANDICAP_MARKET" is stored with index "marketType"  # TODO: step may not exist — verify
    Given "Kafka" payload with headers is set to "domain/fip/market/FIP_Market_Handicap.json"  # TODO: create payload
    When Kafka message with key "marketId" is published to "FIP_INPUT" topic
    Then consume "1" Kafka messages from "MD_OUTPUT_DELTA_OTHERS" topic
    And "Kafka" response matches
      | $.marketChanges[0].marketDefinition.resultType | HANDICAP |

  Scenario: Same FIP message published twice produces no second delta
    Given "Kafka" payload with headers is set to "domain/fip/market/FIP_Market_Win.json"
    When Kafka message with key "marketId" is published to "FIP_INPUT" topic
    Then consume "1" Kafka messages from "MD_OUTPUT_DELTA_OTHERS" topic
    # Second identical message — state unchanged, no delta
    When Kafka message with key "marketId" is published to "FIP_INPUT" topic
    Then "MD_OUTPUT_DELTA_OTHERS" should have no new messages
```
