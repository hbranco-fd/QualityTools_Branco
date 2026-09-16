---
name: service-understand
description: Deeply analyse and document a service repository. Produces per-service docs (stack, purpose, contracts, architecture diagrams, domain model, flows, deployment) plus ecosystem-level outputs (City Map with E2E flow diagrams, Contract Registry, Open Questions Registry). Designed for team onboarding, long-term knowledge preservation, and building a complete city map of the services landscape. Supports a city-map mode to rebuild ecosystem docs from existing service data without analysing a new repo.
---

# Service Understand Skill

Produces structured, code-grounded documentation for any service repository. Based on the FanDuel AI Onboarding canvas, refined with: real code extraction (not just prompting), DC-topology awareness, idempotency as a first-class concern, C4 diagrams, domain modelling, and framework-adaptive contract extraction.

---

## Prerequisites

- Access to the service's GitHub repository (clone or navigate to it)
- Optional: initiative documentation (Confluence page, vault note, ADR) that describes the broader programme this service belongs to — add as context from the start if available

---

## Inputs

Ask the user for:
1. **Repository path or URL** (mandatory — omit if using `city-map` mode)
2. **Initiative / context document** (optional — Confluence URL, vault note path)
3. **Output destination**: vault (`500 - Services/<ServiceName>/`) or repo `docs/` folder, or both
4. **Mode**: `full` (default — analyse a repo and update ecosystem docs) or `city-map` (skip Phases 0–6, rebuild only the ecosystem docs from all existing contract inventories in the vault)
5. **Deployment model** (optional — `v2`, `vm-evo`, `podium`): If known, skips auto-detection in Preflight. If omitted, the skill infers it from repo signals.

---

## Core Principle: Read Before You Describe

**Do not generate documentation from prompts alone.** Use `Glob`, `Grep`, and `Read` to extract real values — topic names, class signatures, config keys, table names — from the actual code. Every claim in the output must be traceable to a file and line number.

---

## Phases

### Preflight — Orientation Check

**Purpose:** Run this before any other phase. Understand what already exists and what conditions apply, so every subsequent phase builds on ground truth rather than assumptions.

**Steps (run these in parallel where possible):**

1. **Repo access and freshness check:** Verify the repo path exists and is readable. Then run:
   ```
   git -C <repo_path> pull
   git -C <config_repo_path> pull   (if a config repo is also used)
   ```
   Report the result — "Already up to date" or "N commits pulled". If `git pull` fails (no network, no remote configured), report the error and the current `HEAD` commit hash + date so the user knows how stale the local copy might be. Do not proceed silently with a stale clone — stale config files produce stale documentation. If the user explicitly confirms they want to proceed with the current local state, continue and stamp the output docs with the HEAD commit hash.

2. **Existing docs check:** Glob `500 - Services/<ServiceName>/` to see which phase docs already exist:
   - If no docs exist → full first-run
   - If some docs exist → identify what changed (check git log, config file mtimes, or ask user)
   - If all docs exist → targeted update (note which phases need revisiting and why)
   
3. **Config access check:** Identify the deployment model and locate the corresponding config repo.

   **a) Detect deployment model** (skip if user provided `deployment_model` input):
   Glob the service repo for the following signals:

   | Model | Signals to look for |
   |---|---|
   | **V2** (Verum + GoCD + Jenkins) | `.gocd.yml`, `gocd/` dir, `Jenkinsfile` with Verum references, Chef cookbook references in CI, absence of Helm/k8s manifests |
   | **VM Evo** (AWS AMI) | `*.pkr.hcl`, `packer/` dir, AMI/EC2 references in CI config, Terraform with `aws_autoscaling_group` or `aws_instance` resources |
   | **Podium** (Kubernetes) | `helm/` or `charts/` dir, `k8s/` dir, any `*.yaml` containing `kind: Deployment`, `Dockerfile`, `skaffold.yaml` |

   If signals are ambiguous or mixed (e.g. mid-migration service), note all candidates and ask the user to confirm before proceeding.

   **b) Locate the config repo** based on the detected (or provided) model:

   - **V2** — Config lives in the `Flutter-Global` GitHub org:
     - Check if `Flutter-Global/all-chef-fdg` or `Flutter-Global/all-ansible-fdg` is cloned locally.
     - Search for cookbooks (Chef) or roles/playbooks (Ansible) named after the service.

   - **VM Evo / Podium** — Config lives in the `fanduel` GitHub org in a service-specific repo:
     1. Try each of these naming patterns in order (replace `<name>` with the service name):
        - `fanduel/sb-<name>-infra`
        - `fanduel/<name>-service-deploy`
        - `fanduel/<name>-service-infra`
        - `fanduel/sb-<name>-deploy`
     2. Check if any matching repo is cloned locally first.
     3. If not found locally, search GitHub: `gh search repos --owner=fanduel <name>` and filter results containing `infra`, `deploy`, or `config` in the repo name.
     4. If still not found, report it as unresolved — config extraction from this repo will be partial.

   **c) If the config repo is found and cloned locally**, pull it as part of step 1's freshness check. If found on GitHub but not cloned, note the URL so the user can clone it if deeper config analysis is needed.

4. **Contract inventory backfill check:** If `02-contract-inventory.md` exists but lacks `contracts` frontmatter, flag it — Phase 2 will generate and add the block before proceeding to Phase 2b.

5. **City-map mode check:** If mode is `city-map`, skip to Phase 7 immediately. Otherwise continue.

**Announce before proceeding:**
```
Preflight complete:
- Repo: [path] — [accessible / NOT FOUND]
- Repo git state: [pulled: N commits / already up to date / pull failed — HEAD abc1234 (YYYY-MM-DD)]
- Deployment model: [v2 / vm-evo / podium (auto-detected) | v2 / vm-evo / podium (user-provided) | ambiguous — awaiting user confirmation]
- Config repo: [accessible at path / found on GitHub at <url> (not cloned locally) / not found — config extraction will be partial]
- Config repo git state: [pulled: N commits / already up to date / pull failed — HEAD abc1234 | n/a — not cloned]
- Config repo signals: [chef cookbook "<name>" / ansible role "<name>" / helm chart at <path> / terraform at <path> | none found]
- Existing docs: [none / partial (phases X, Y, Z) / all 7 phases]
- Backfill needed: [yes — 02-contract-inventory.md lacks contracts frontmatter / no]
- Mode: [full / city-map]
- Plan: [fresh run / update phases X, Y, Z / city-map rebuild only]
```

Do not proceed if the repo is not accessible. Report the error and ask the user to check the path or clone the repo.

---

### Phase 0 — Stack Fingerprint

**Purpose:** Discover the actual stack of this service. No assumptions.

**Extract ground truth:**

```
Glob: **/pom.xml, **/build.gradle*, **/build.sbt, **/build.gradle.kts
Glob: **/*.proto, **/*.avsc, **/*.thrift
Glob: **/application*.yml, **/application*.properties, **/application*.conf
Read: pom.xml / build.gradle / build.sbt (declared dependencies + versions)
```

**From declared dependencies, identify:**

| Category | What to look for |
|---|---|
| Language | Java, Kotlin, Scala — version |
| App framework | Spring Boot, Akka HTTP, Pekko, Cougar, Play, bare Netty |
| Concurrency model | Spring threads, Akka/Pekko actors, Flink operators, Storm topology |
| Messaging | Kafka, Pulsar, RabbitMQ — and which client library |
| Stream processing | Flink, Storm, Akka Streams, Pekko Streams |
| Databases | Cassandra, MySQL, PostgreSQL, Elasticsearch — and ORM/driver |
| HTTP clients | RestTemplate, WebClient, Feign, Akka HTTP client, OkHttp |
| Build tooling | Maven, Gradle, SBT |
| Test frameworks | JUnit, ScalaTest, Specs2, TestContainers |
| Non-obvious | Cougar, internal library versions, custom frameworks |

**Output:** A table — technology, version, role in this service. Every row backed by a dependency declaration.

**Do NOT assume a "standard stack" — every service is read independently.** Spring + Kafka + Cassandra, Scala + Akka Streams + Pulsar, Flink + Pekko, Cougar + RabbitMQ — all are possible.

**Calibration:** note any technology that differs from adjacent services in the same capability area. Different framework = different extraction patterns in Phase 2.

---

### Phase 1 — Service Compass

**Purpose:** What is this service, what does it NOT do, where does it sit?

**Prompt framing:**
> *"Summarise this repository at a high level. Describe what this service does, what problem it solves, and where it sits within the broader system. Use any initiative documentation provided as context. Explicitly state what this service is not responsible for. Write in business terms, avoiding implementation detail."*

**Output:**
- 2-paragraph business description (no implementation detail)
- Explicit scope boundary: what the service is NOT responsible for
- Deployment location: environment, cloud, DC (super state / betting state / Outpost), cluster/namespace
- Link to deploy scripts for anyone needing to go deeper

**Revision trigger:** revisit after Phase 2 if contracts reveal a different picture. Lock after that unless a factual error is found.

---

### Phase 2 — Contract Inventory

**Purpose:** All input/output contracts extracted from the actual code. The structural backbone.

**Extraction patterns adapt to the stack identified in Phase 0.**

#### Messaging consumers

Grep strategy by framework:
- **Spring Kafka**: `@KafkaListener`, `@KafkaHandler`
- **Akka/Pekko Streams**: `Consumer.plainSource`, `Consumer.committableSource`, `Consumer.atMostOnceSource`
- **Flink**: `FlinkKafkaConsumer`, `KafkaSource`, `KafkaRecordDeserializationSchema`
- **Storm**: `KafkaSpout`, custom spout `nextTuple` implementations
- **Cougar**: subscription declarations, protocol buffer bindings in IDD/SDD files

For each consumer, document:

```
Topic:          [exact string from annotation/config]
Consumer group: [exact string]
Parallelism:    [concurrency/thread count/parallelism setting]
Offset reset:   [earliest = needs historical data | latest = real-time only]
Offset commit:  [auto | manual — manual implies at-least-once in code]
Schema:         [proto/avro class, file reference]
Idempotency:    [yes/no — how: dedup key, upsert, conditional write, idempotent producer ID]
Dead letter:    [DLT topic name | MISSING — flag as gap]
DC placement:   [super state | betting state | Outpost]
Evidence:       [file:line]
Open questions: []
```

#### Messaging producers

Grep strategy by framework:
- **Spring Kafka**: `KafkaTemplate.send`, `@SendTo`
- **Akka/Pekko Streams**: `Producer.plainSink`, `Producer.committableSink`, `Producer.flexiFlow`
- **Flink**: `FlinkKafkaProducer`, `KafkaSink`
- **Cougar**: publisher declarations, event type bindings

For each producer, document:

```
Topic:        [exact string]
Key strategy: [what is the message key and why]
Durability:   [acks setting: all | 1 | 0]
Idempotent:   [producer idempotency enabled?]
Schema:       [proto/avro class, file reference]
DC placement: [super state | betting state | Outpost]
Evidence:     [file:line]
```

#### API / service interfaces

Grep strategy by framework:
- **Spring MVC/WebFlux**: `@RestController`, `@GetMapping`, `@PostMapping`, `@RequestMapping`
- **Akka HTTP / Pekko HTTP**: `Route`, `path()`, `get {}`, `post {}` DSL
- **Cougar**: IDD/SDD service definitions, operation descriptors, `.wsdl` / `.xml` bindings
- **gRPC**: `.proto` service definitions, `@GrpcService`

For each endpoint: path, method, request/response contract type, auth, sync vs async.

#### Database access

Grep strategy by driver:
- **Spring Data Cassandra**: `@Table`, `@PrimaryKey`, `@PrimaryKeyColumn`, `CassandraRepository`
- **Phantom DSL (Scala)**: table object definitions, column declarations
- **Plain CQL**: `PreparedStatement`, `SimpleStatement`, CQL strings
- **MySQL/Postgres — JPA**: `@Entity`, `@Repository`, `@Query`
- **MySQL/Postgres — JOOQ**: `dslContext.select`, table/field references
- **Elasticsearch**: `ElasticsearchRepository`, `RestHighLevelClient`, `SearchRequest`

For each data store:

```
Store:          [Cassandra | MySQL | ES | ...]
Table/Index:    [exact name]
Partition key:  [what drives the access pattern]
Clustering key: [ordering, if Cassandra]
TTL:            [value if set — transient data | none — permanent data]
Access pattern: [read | write | read-write]
Write pattern:  [upsert | insert | delete | conditional]
Evidence:       [file:line]
```

#### Scheduled triggers

- **Spring**: `@Scheduled`, `TaskScheduler`
- **Akka/Pekko**: `system.scheduler.scheduleAtFixedRate`, `Timers` trait
- **Flink**: window triggers, `ProcessingTimeService`, `TimerService`
- **Cron**: expressions in config files

#### Stream processing topology (Flink/Storm/Akka Streams)

- Source operators → transform operators → sink operators (with names)
- State stores: keyed state, operator state, RocksDB backend
- Windowing: tumbling, sliding, session — trigger type
- Checkpointing: interval, mode (exactly-once / at-least-once)
- Parallelism per operator

**Then produce:**
- Named, high-level description of each distinct flow (input → processing → output)
- Mermaid flow diagram covering all flows, including error paths
- **DC topology flag**: call out any cross-DC calls explicitly — these have latency and data residency implications

**Contract index (frontmatter):** At the same time as the body, produce a structured `contracts` YAML block in the frontmatter of `02-contract-inventory.md`. This is the machine-readable index that enables cross-service referencing in Phase 2b. Both are generated from the same extraction — the body is the human-readable ground truth, the frontmatter is the join index.

```yaml
contracts:
  kafka_consumed:
    - topic: "ppb.stream.fd.instructions.{sport}"   # use {sport} for parameterised topics
      source_service: FIP
    - topic: "catalog.risk.domain.fd.{sport}.delta.v1"
      source_service: PCSA-RD
  kafka_produced:
    - topic: "catalog.risk.domain.fd.{sport}.delta.v1"
      known_consumers: [PCSA-RS, PCSA-MD]
  databases:
    - type: cassandra
      keyspace_pattern: "pcra_rd_*"
      host_pattern: "{dc}-pcardfd-prdss.prd.fndlsb.net"
  api_exposed: []
  api_consumed: []
```

**Backfill rule:** If the vault already contains a `02-contract-inventory.md` for this service but it lacks the `contracts` frontmatter block, generate and add the block from the body content before proceeding to Phase 2b. Log: "Backfilled contract index for `<ServiceName>`."

**Revision trigger:** revise Phase 1 if this changes the high-level picture.

---

### Phase 2b — Cross-Service Contact Points

**Purpose:** Identify every contact point between this service and the rest of the documented ecosystem. Runs immediately after Phase 2, before diagrams are produced.

**Procedure:**

1. **Scan existing contract inventories.** Glob `500 - Services/*/02-contract-inventory.md`. For each file found, read the `contracts` frontmatter block. Build an in-memory index: `{ service_name → { kafka_consumed, kafka_produced, databases, api_exposed, api_consumed } }`.

2. **Also scan stub notes.** Glob `500 - Services/*.md` (single-file stubs: DM, FMG, IPMA, KCD, PBT, SEP, SMP, Eviction Stream). These lack structured frontmatter but may reference topic names or service names inline — treat any matches as Inferred confidence.

3. **Match on Kafka topics.** For each topic this service produces, check if any other service's `kafka_consumed` list contains the same topic (and vice versa). Normalize before comparison: replace sport/region/env suffixes with `{sport}`, `{region}`, `{env}` wildcards. A match at pattern level is sufficient.

4. **Match on databases.** If two services share a Cassandra keyspace name or host pattern, flag it as a shared database edge. This is a strong coupling signal (e.g., `pcra_md_cross_entity_validation` shared between PCSA-MD and PCSA-MS).

5. **Match on APIs.** If this service's `api_consumed` list matches another service's `api_exposed`, record the dependency.

6. **Classify confidence:**

| Tier | Condition |
|------|-----------|
| Confirmed | Both services have `contracts` frontmatter with matching resource names |
| One-sided | This service's inventory names a resource; the other service exists but has no `contracts` frontmatter |
| Inferred | Service referenced inline in a stub note or mentioned in initiative docs only |

7. **Produce `02b-cross-service-contacts.md`:**

```markdown
---
tags: [Service, <ServiceName>, CrossServiceContacts]
generated: <YYYY-MM-DD>
---
# <ServiceName> — Cross-Service Contact Points

## Kafka Topic Connections

| Direction | Topic | This service | Other service | Confidence | Evidence |
|-----------|-------|-------------|---------------|------------|----------|
| → produces | `catalog.risk.domain.fd.{sport}.delta.v1` | PCSA-RD (producer) | [[PCSA]] (PCSA-RS consumer) | Confirmed | [[02-contract-inventory]] |
| ← consumes | `ppb.stream.fd.instructions.{sport}` | PCSA-RD (consumer) | FIP (producer) | One-sided | [[02-contract-inventory]] |

## Shared Databases

| Resource | This service | Other service | Confidence | Evidence |
|----------|-------------|---------------|------------|----------|
| `pcra_md_cross_entity_validation` | PCSA-MD | [[PCSA]] (PCSA-MS) | Confirmed | md-db-init.cql, ms-db-init.cql |

## API Dependencies

_(empty if none found)_

## Unresolved References

Services mentioned in contracts but not yet documented in the vault:

- **SIB** — listed as consumer of `catalog.market.stream.fd.default`; not documented
- **LSET** — listed as consumer of `catalog.risk.stream.fd.default.full`; not documented
```

**After producing this file:** proceed to Phase 3. The cross-reference data is used in Phase 3a to populate the C4 Context diagram with confirmed relationships.

---

### Phase 3 — Architecture Map, Diagrams & Domain Model

**Purpose:** Give the team a visual and conceptual model before they read the flow detail.

#### 3a — C4 Diagrams

Use the `/diagram` skill to generate all diagrams in Mermaid format. Start at Context and drill down only as far as complexity warrants.

**C4 Context (always produce):**
```mermaid
C4Context
  Person or System_Ext for each upstream data source
  System_Boundary for this service
  System_Ext for each downstream consumer
  DC annotations where relevant (super state / betting state / Outpost)
```

**Cross-reference enhancement:** Before generating the C4 Context, read `02b-cross-service-contacts.md`. For every Confirmed or One-sided connection listed there, add the counterpart service as a `System` or `System_Ext` node and add the corresponding `Rel()` line with the Kafka topic or API label. This replaces guesswork with grounded data. Inferred connections may be included but should be commented with `// inferred`.

**C4 Container (produce if multiple deployable units exist):**
- Each deployable component (main service, sidecar, Flink job, GSSP instance)
- Communication protocols (Kafka, HTTP, gRPC, Pulsar)
- Data stores (Cassandra keyspace, MySQL DB, Elasticsearch index)

**C4 Component (produce for complex services with distinct internal modules):**
- Inbound adapters
- Domain core
- Outbound adapters

**Sequence diagrams (one per flow from Phase 2):**
- Trigger → service internals → external calls → output
- Include the error path where it produces a different output

**Flow/decision diagram (Mermaid flowchart, one per flow):**
- Decision-level view of the main processing logic
- Branch on: message type, entity state, config flag, error condition

Save all diagrams to `docs/diagrams/` as separate `.md` files containing the Mermaid code block.

**Calibration:** compare C4 Context with any existing architecture notes in the vault (`500 - Services/`, `310 - Initiatives/`) and flag discrepancies.

#### 3b — Hexagonal Architecture Map

Identify the three layers explicitly, adapted to whatever framework is in use:

| Layer | What to look for |
|---|---|
| **Inbound ports** | Kafka consumers, REST/Cougar controllers, schedulers, Flink sources |
| **Domain layer** | Services, aggregates, domain events, use cases |
| **Outbound ports** | Repositories, Kafka producers, HTTP clients, Flink sinks |

For Flink/Storm topologies: map source → transform chain → sink as the equivalent structure.

Configuration entry points: where external config drives domain behaviour (feature flags, thresholds, routing rules). Note that config values may live outside the service repo — in the config repo identified during Preflight (Chef cookbook, Ansible role, Helm values files, Terraform variables). Cross-reference it when tracing how a config value reaches the service.

#### 3c — Domain Model

**Prompt framing:**
> *"Identify the domain entities this service manages. For each, describe what states it can be in, what causes transitions between states, and what business rules must always hold. Do not describe class structure or method signatures."*

Document:
- Domain entities: name, key fields, business meaning
- States: what states each entity can be in and what they mean
- Transitions: trigger (message type / API call / scheduler) → state change → output produced
- Invariants: what must always be true
- Aggregates or bounded context boundaries if the service is DDD-structured

**Flag any business logic with no documentation source** — embedded logic that can only be understood by reading the code is a risk item.

---

### Phase 4 — Flow Deep Dives

**Purpose:** What does the system decide, and why — traced from code, not inferred.

Work through each flow from Phase 2 in turn.

#### For each flow:

**Trace the call chain:**
- Entry point: which consumer/endpoint/scheduler triggers this flow
- Follow the chain: method → service → repository/producer (with file references)
- Identify state changes along the path
- Note where external calls are made and what they return

**Document the decisions:**
> *"Describe what the system decides and why, not how the code is structured. Do not describe class structure or method signatures."*
- What choices does the system make and on what basis?
- What data drives each decision?
- What triggers the non-happy path?

**Error handling:**
- Transient failure: retry policy, backoff, max attempts
- Permanent failure: dead letter handling, alerting mechanism
- Poison pill: is there detection/skip logic? If not, flag as a gap.
- Downstream timeout: what is the fallback behaviour?

**Idempotency (mandatory for all messaging consumers):**
- Is this flow safe to replay? How?
- Deduplication mechanism: dedup key in DB, idempotent upsert, check-before-write, conditional update
- What happens on double-processing if the mechanism fails?

**Output in business terms:**
- What does the output represent to a downstream consumer?
- Which downstream systems or teams depend on this output?

**After all flows:** ask the AI to review Phases 1 and 2 and flag factual corrections. Apply corrections only — do not routinely rewrite.

---

### Phase 5 — Deployment Map

**Purpose:** How does this service get to production and stay there.

Use the deployment model identified in Preflight to guide where to look. Point at: deploy scripts, pipeline config, environment config files — in both the service repo and the config repo located in Preflight.

**Prompt framing:**
> *"Describe how this service is deployed. Do not explain how the scripts work mechanically. Describe what happens at each stage, what must be in place before deployment, and what a developer needs to know to trigger or diagnose a deployment."*

**Extraction guide by deployment model:**

| Model | Where to look | What to extract |
|---|---|---|
| **V2** (Verum + GoCD + Jenkins) | `Jenkinsfile`, GoCD pipeline YAML, `Flutter-Global/all-chef-fdg` cookbooks or `Flutter-Global/all-ansible-fdg` playbooks | GoCD pipeline stages, Verum deployment flow, Chef/Ansible config management, Jenkins trigger conditions |
| **VM Evo** (AWS AMI) | Packer templates, Terraform in the `fanduel/<name>-*` infra repo, CI pipeline config | AMI build pipeline, Terraform infrastructure (ASG/EC2), config injection mechanism (user-data, SSM, S3) |
| **Podium** (Kubernetes) | Helm chart in the `fanduel/<name>-*` deploy repo, `Dockerfile`, `skaffold.yaml`, CI pipeline config | Helm chart structure, k8s namespace/cluster per environment, deployment strategy (rolling/canary/blue-green), ConfigMaps/Secrets sources, service mesh if present |

**Output:**
- Deployment model: V2 / VM Evo / Podium — and the config repo used
- Where it runs: cloud provider, region, DC (super state / betting state / Outpost), cluster/namespace per environment
- How deployment is triggered: pipeline on merge, manual, scheduled — and who can trigger it
- Pipeline stages in plain terms (not script detail)
- Pre-deployment dependencies: infrastructure, upstream services, secrets, certificates
- Environment-specific config and where values live (cross-reference the config repo found in Preflight)
- Success confirmation: health check endpoint, log signals, dashboards
- Rollback: mechanism if it exists; explicit note if none

---

### Phase 6 — README Audit

**Purpose:** Leave the repo better than you found it. Done last, produces a PR.

**Prompt framing:**
> *"Review the existing README for this repository. Identify anything factually incorrect or missing based on everything you now know about this service. Report what needs changing rather than rewriting the whole thing."*

README should cover only:
- What the service does (one paragraph, business terms)
- Tech stack (brief list)
- How to run locally + how to run tests (exact commands)
- Link to `docs/` for architecture, flows, and deployment detail

PR adds only what is missing. Does not rewrite from scratch unless the README is absent or fundamentally wrong.

---

### Phase 7 — Ecosystem Updates

**Purpose:** Maintain a complete, accurate city map of the services ecosystem. Runs at the end of every `service-understand` execution, and is the only phase that runs in `city-map` mode.

This phase is **idempotent and incremental**: always rebuilds from all existing data rather than patching. Re-running produces the same output.

**Data source for all sub-phases:** Glob `500 - Services/*/02-contract-inventory.md` (structured frontmatter), `500 - Services/*/02b-cross-service-contacts.md` (cross-reference data), and `500 - Services/*.md` (stub notes).

---

#### Phase 7a — City Map

Produces/updates `500 - Services/City Map.md` and `500 - Services/City Map.canvas`.

**City Map document structure:**

**1. Service Registry** — Table of all known services (from contract inventories, cross-service contacts, and stubs), with role, stack summary, documentation status, DC placement, and wikilink.

| Service | Role | Stack | Status | DC | Docs |
|---------|------|-------|--------|----|------|
| PCSA-RD | Risk Domain aggregator | Scala / Pekko / Cassandra | Full | Super state USE1/USE2 | [[PCSA]] |
| FIP | Feed Input Processor | — | Inferred | — | — |

Status values: `Full` (has all service-understand docs) · `Stub` (single-file note only) · `Inferred` (referenced in contracts but no vault file)

**2. System Context Diagram** — Mermaid C4Context covering the entire known ecosystem. Use `System_Boundary` groups for capability areas:
- `GBP Evo Catalogue` — PCSA variants, FIP, GTH, GMA/IPMA, Sportex, PCSS, PCC, SEP, LSET
- `OBP Catalogue` — DCP, Catalogue API, OBP Catalogue Consolidator
- `Distribution` — downstream consumers (SIB, SPB, FCQ, SMP, SMR, etc.)

Edges are labelled with the Kafka topic pattern or protocol. Inferred-only services appear as `System_Ext` with a comment noting the evidence source.

**3. End-to-End Flow Diagrams** — One Mermaid flowchart per major data flow path, tracing data across service boundaries. These are cross-service flows, not per-service flows (those live in `05-flow-deep-dives.md`). Detect flows by chain-tracing: if service A produces a topic that service B consumes, and B produces a topic C consumes, that is an A → B → C flow chain.

Examples of flows to produce when data is available:
- **Catalogue Event Flow (Risk path):** `FIP → PCSA-RD → PCSA-RS → LSET`; include Kafka topic names at each hop
- **Catalogue Event Flow (Market path):** `FIP + PCSA-RD → PCSA-MD → PCSA-MS → [SIB, SPB, FCQ, SMP]`
- **Override Flow:** `GMA/IPMA → PCSA-RD → Risk Domain stream`
- **Eviction Flow:** `PCSA-MD (resulted) → PCSS → [PCSA-XD, PCC]`
- **OBP Catalogue Flow:** `DCP Flink → catalogue-stream → [Catalogue API, OBP Catalogue Consolidator → PCSS]`

For each flow diagram, show: trigger → each service hop (labelled with its role) → Kafka topic label on each edge → final consumers.

**4. Infrastructure Topology** — Two sub-sections:

*Kafka Clusters:* Table listing each Kafka cluster (MFS USE1, MSK event-streaming USE2, AWS MSK eu-west-1, catalog-backbone, FOK per betting state) with the services that produce/consume on it and the DC it serves.

*Cassandra Clusters:* Table listing each Cassandra cluster/host pattern with the services using it, keyspace patterns, and DC placement.

**5. Edges Table** — Complete inventory of every known service-to-service connection:

| Source | Target | Type | Resource | Confidence | Evidence |
|--------|--------|------|----------|------------|----------|
| FIP | PCSA-RD | Kafka | `ppb.stream.fd.instructions.{sport}` | One-sided | [[02-contract-inventory\|PCSA 02]] |
| PCSA-RD | PCSA-RS | Kafka | `catalog.risk.domain.fd.{sport}.delta.v1` | Confirmed | [[02-contract-inventory\|PCSA 02]] |

**6. Documentation Gaps** — Services that appear in connections but lack documentation. For each: name, how many confirmed/one-sided edges touch it, which flows it participates in, and a suggested next step (e.g., "Run service-understand against `Flutter-Global/lset-service`").

**7. Metadata** — Last updated date and which service execution triggered this update.

**City Map canvas (`500 - Services/City Map.canvas`):**

Use the `obsidian:json-canvas` skill conventions. Each service gets a file node (pointing to its folder or stub note). Edges carry the Kafka topic pattern or protocol as the label. Group nodes used for capability areas. Color coding: `"4"` (green) = Full, `"2"` (orange) = Stub, `"6"` (purple) = Inferred. Spatial layout: upstream sources on the left, downstream consumers on the right, shared infrastructure below the service layer.

---

#### Phase 7b — Contract Registry

Produces/updates `500 - Services/Contract Registry.md`.

**Purpose:** Reverse index of every Kafka topic, database, and API across all documented services. "Which services touch this topic?" answered in one lookup. Critical for impact analysis.

**Kafka Topics section:**

| Topic | Producer | Consumers | Schema | DC | Evidence |
|-------|----------|-----------|--------|----|----------|
| `ppb.stream.fd.instructions.{sport}` | FIP | PCSA-RD, PCSA-MD | FIP Instruction (Protobuf, fip-contracts v2.0.7) | Super state | [[02-contract-inventory\|PCSA 02]] |
| `catalog.risk.domain.fd.{sport}.delta.v1` | PCSA-RD | PCSA-RS, PCSA-MD | GlobalRiskInstruction (Protobuf) | Super state | [[02-contract-inventory\|PCSA 02]] |

Below each topic (or as a separate "Impact Analysis" section), list the services affected by a schema change to that topic. Example: "Changing `catalog.risk.domain.fd.{sport}.delta.v1` affects: PCSA-RD (producer), PCSA-RS (consumer), PCSA-MD (consumer)."

**Databases section:** Every known keyspace, table, or index with owning service(s), access pattern (read/write/read-write), and DC. Flag any keyspace shared between multiple services — these are high-coupling points.

**APIs section:** Every known REST/gRPC/Cougar endpoint exposed by a documented service, with known consumers.

**Last updated** stamp.

---

#### Phase 7c — Open Questions Registry

Produces/updates `500 - Services/Open Questions.md`.

**Purpose:** Consolidated view of all unresolved questions across every documented service, ranked by risk. Shows systemic gaps that appear across multiple services.

**Data source:** Scan all `02-contract-inventory.md`, `02b-cross-service-contacts.md`, and hub docs (e.g., `PCSA.md`) for open questions sections. Extract each item with its risk rating and source wikilink.

**By Risk section:**

| Risk | Service | Question | Source |
|------|---------|----------|--------|
| High | PCSA | Dead letter topics not found in any config or Confluence | [[02-contract-inventory\|PCSA 02]] |
| Medium | PCSA | `rs.publishing.enabled = false` in prd — active/passive flag? | [[02-contract-inventory\|PCSA 02]] |

**By Service section:** Same data grouped by service. Useful for routing questions to the right team.

**Systemic Patterns section:** When the same class of question appears across multiple services, flag it as a systemic pattern rather than a per-service issue. Detection rule: if 2+ services have an open question about the same topic category (e.g., "dead letter handling", "offset reset policy", "idempotency under replay"), group them and call out the pattern explicitly. Example: "Dead letter handling is unconfirmed in PCSA, FES, and SEP — this is a systemic gap, not isolated."

**Last updated** stamp.

---

#### Standalone `city-map` mode

When the skill is invoked with mode `city-map` (no repository path provided):

1. Skip Phases 0–6 entirely
2. Ask: "Do you want to seed any inferred services from initiative docs? (e.g., `Catalogue Current State - Apr 2026.md`)" — if yes, read those docs and extract service names and relationships at Inferred confidence before running Phase 7
3. Run Phase 7a, 7b, 7c from all existing vault data
4. Report: how many services discovered, how many edges confirmed vs inferred, which documentation gaps are highest priority

---



Save documents to:
- **Vault**: `500 - Services/<ServiceName>/<doc-name>.md`
- **Repo**: `docs/<doc-name>.md`
- **Diagrams**: `docs/diagrams/<diagram-name>.md`

Naming:
- `00-stack-fingerprint.md`
- `01-service-compass.md`
- `02-contract-inventory.md` (with `contracts` frontmatter block)
- `02b-cross-service-contacts.md`
- `03-architecture-diagrams.md` + `docs/diagrams/c4-context.md`, `c4-container.md`, `flow-<name>.md` etc.
- `04-domain-model.md`
- `05-flow-deep-dives.md`
- `06-deployment-map.md`
- `07-readme-audit.md` → PR

**Ecosystem-level documents** (written to `500 - Services/`, shared across all services):
- `City Map.md` + `City Map.canvas`
- `Contract Registry.md`
- `Open Questions.md`

---

## Document Output Structure

Each contract claim follows: **value → evidence (file:line) → open questions**

Example:
```
**Topic:** `catalogue-stream`
**Consumer group:** `pcss-catalogue-reader`
**Schema:** `CatalogueMessage` (protobuf — `src/main/proto/catalogue.proto:12`)
**DC:** super state (USE1/USE2)
**Idempotency:** upsert by `entityId` in Cassandra (`CatalogueRepository.upsert:47`)
**Dead letter:** `catalogue-stream-dlt` — logged + alert via GAMB
**Open questions:**
- [ ] `auto.offset.reset=earliest` — intentional? Implies full history bootstrap.
- [ ] No retry on downstream HTTP call at `EventEnricher:89` — deliberate?
```

---

## Validation Checklist

Surface this checklist explicitly at the end. These documents are not complete until a reviewer with service knowledge has signed off.

- [ ] Service purpose statement is correct
- [ ] All inputs and outputs captured in Phase 2 with real values (not inferred)
- [ ] DC placement is correct for each contract
- [ ] Architecture diagrams match the actual deployment topology
- [ ] Domain entities and states match actual behaviour (Phase 3)
- [ ] Each flow description reflects what the service actually does (Phase 4)
- [ ] Idempotency assessment is accurate for all messaging consumers
- [ ] Deployment description matches the current pipeline (Phase 5)
- [ ] All open questions have been reviewed — each needs an owner or a decision
- [ ] Cross-service contact points reviewed — no false matches, no missed connections
- [ ] City Map service registry is complete; all services in contracts appear in the registry
- [ ] City Map end-to-end flow diagrams trace correct paths through the system
- [ ] Contract Registry lists all topics/databases with correct producer/consumer mappings
- [ ] Open Questions Registry captures all unresolved items; systemic patterns flagged

> **These documents are not complete until a reviewer with existing service knowledge has confirmed the checklist above. Even a 30-minute review pass catches subtle inaccuracies in business logic and edge case handling.**
