---
name: auto-documentation
description: Generate and keep up to date Confluence documentation for FanDuel services — one main service page plus one child page per feature — grounded in real code (stack, contracts, architecture, domain model, flows, deployment). Supports a create mode and a sweep mode that detects code-vs-docs drift and refreshes only affected pages; can run unattended. Use when the user wants service docs in Confluence, a service page with feature sub-pages, to document a service/repo, or a recurring documentation refresh.
---

# AutoDocumentation

Produces structured, code-grounded documentation for a service repository and publishes it to Confluence:

```
<ServiceName>                       (main page)
├── <ServiceName> — <Feature A>     (child page)
├── <ServiceName> — <Feature B>
└── ...
```

Core concerns built in: real code extraction (not prompting), DC-topology awareness, idempotency as a first-class concern, C4 diagrams, domain modelling, framework-adaptive contract extraction, and preservation of human edits across runs.

---

## Core Principle: Read Before You Describe

**Do not generate documentation from prompts alone.** Use `Glob`, `Grep` and `Read` to extract real values — topic names, consumer groups, class signatures, config keys, table names — from the actual code. Every claim in the output must be traceable to a file and line number. No evidence → no claim; record it as an Open Question instead.

**Source of truth = code only.** Feature names and grouping are derived from code, not from Jira, product docs or existing Confluence. They are a first draft; humans adjust them to product language on the page and the skill preserves those edits (see "Human edits").

---

## Inputs & Config

### Interactive (create mode)

Ask the user for anything missing:
1. **Repository path or URL** (mandatory)
2. **Confluence location** — `cloud_id` (site), `space_key`, `parent_page_id`
3. **Initiative / context document** (optional — Confluence URL, ADR) describing the broader programme the service belongs to
4. **Deployment model** (optional — `v2`, `vm-evo`, `podium`). If omitted, inferred in Preflight.

### Config file (sweep mode / unattended)

`auto-documentation-config.yaml` (path given by the caller):

```yaml
confluence:
  cloud_id: <site, e.g. fanduel.atlassian.net>
  space_key: <SPACEKEY>
  parent_page_id: <id of the page under which service pages live>
services:
  - name: PCSA-MD
    repo: https://github.com/Flutter-Global/pcsa-md-service.git
    branch: main
    page_id: <optional — set after first run; else found by title>
    config_repo: <optional — overrides Preflight discovery>
    deployment_model: <optional — v2 | vm-evo | podium>
    auto_tier: significant      # significant | all | report-only
defaults:
  auto_tier: significant
```

Missing file or empty `services:` → report "0 serviços configurados — nada a fazer" and stop. Not an error.

---

## Modes

- **create** — one service. Full extraction (Phases 0–5), feature identification, create/update main page + feature pages.
- **sweep** — all configured services. Detect drift, refresh only what changed. When unattended, **no interactive gate**: select per `auto_tier`.
- **report-only** — sweep without writing anything.

---

## Two-Phase Invocation (large or unfamiliar services)

To keep the main context lean on large codebases (>50k LOC, first-time analysis, noisy previous runs):

**Phase A — exploration subagent (read-only).** Dispatch a read-only subagent:

```
Agent({
  subagent_type: "general-purpose",
  description: "Explore <ServiceName> repo and write findings",
  prompt: "Read-only investigation of <repo_path>. Run Preflight steps 1 and 3, then Phases 0–3 of the AutoDocumentation procedure (stack fingerprint, purpose, contracts, architecture, domain model). Do NOT produce final docs or touch Confluence. Write all findings — real values extracted from code, with file:line citations — to <scratch>/exploration-<ServiceName>-<YYYYMMDD-HHmm>.md. Markdown, H2 per phase, bullet points, no prose summaries."
})
```

The findings file is scratch: build system, framework/versions; purpose, bounded context, DC placement; all Kafka topics, REST endpoints, gRPC contracts, DB schemas with real names; architectural classes, hexagonal boundaries, patterns; core domain entities and relationships. The subagent's hundreds of Grep/Read calls stay out of the main context.

**Phase B — main agent.** Reads the findings file, runs Phases 4–5 directly (flows, deployment — need live tracing), identifies features, writes Confluence pages, deletes the findings file.

Default (single-phase): small service, targeted update, sweep refresh.

---

## Preflight — Orientation Check

Run before any phase. **Step 1 must complete before Step 2.**

### 1. Repo pull (gate for all change detection)

Clone (shallow, deepen if needed for diff) or `git -C <repo> pull`. Same for the config repo if one is used. Report "Already up to date" / "N commits pulled". On failure, report the error and current `HEAD` hash + date.
- Interactive: don't proceed silently on a stale clone — ask; if user confirms, continue and stamp that HEAD.
- Sweep: mark service `stale (pull failed)`, continue with others, never abort the run.

**Do not read source files or existing Confluence pages before this completes.**

### 2. Existing docs check and change scoping

Locate the main page (`page_id`, else `getConfluencePageDescendants(parent_page_id)` matched by title).
- No page → full first run.
- Page exists → read `source-head:` from its metadata panel, then:
  1. If the SHA exists in the repo (`git cat-file -e <sha>`) → precise baseline. Else use the `generated:` date → approximate baseline (flag it).
  2. `git rev-list --count <sha>..HEAD` (or `git log --since=<date> --oneline`). Zero → "No changes since last scan (<sha/date>)" → stop for this service.
  3. `git diff --name-only <sha>..HEAD` (or `git log --since=<date> --name-only --pretty=format: | sort -u`).
  4. Map changed files to phases:
     - `pom.xml` / `build.gradle*` / `*.sbt` / `package.json` → Phase 0
     - `*Controller*`, `*Consumer*`, `*Producer*`, `*Repository*`, `*.proto`, `*.avsc`, `application*.yml` → Phase 2 (+2b, 3a)
     - domain entities, state machines, aggregates → Phase 3c / 4
     - CI/CD, Dockerfile, Helm, Terraform, Packer → Phase 5
  5. Map changed files to features (entry points + call chains recorded on feature pages) → affected feature pages.
  6. Report plan: "Phases X, Y; features F1, F2 need revisiting; rest unchanged."

**Anchor on `source-head`, never on per-page `generated:` dates** — pages are re-stamped individually, so a date anchor over-counts drift.

### 3. Config access check

**a) Detect deployment model** (skip if provided):

| Model | Signals |
|---|---|
| **V2** (Verum + GoCD + Jenkins) | `.gocd.yml`, `gocd/` dir, `Jenkinsfile` with Verum refs, Chef cookbook refs in CI, no Helm/k8s manifests |
| **VM Evo** (AWS AMI) | `*.pkr.hcl`, `packer/` dir, AMI/EC2 refs in CI, Terraform with `aws_autoscaling_group` / `aws_instance` |
| **Podium** (Kubernetes) | `helm/` or `charts/`, `k8s/`, `*.yaml` with `kind: Deployment`, `Dockerfile`, `skaffold.yaml` |

Ambiguous/mixed (mid-migration) → note all candidates. Interactive: ask to confirm. Unattended: pick the strongest signal, flag for human review.

**b) Locate the config repo:**

- **V2** — `Flutter-Global` org. Check in order:
  - **b.1 Per-service `-fdg` repo** (Storm topologies and similar; environment overrides FD/UKI). Known: FIP → `Flutter-Global/fip-service-fdg`; PBT → `Flutter-Global/pbt-config-fdg`. Patterns: `<name>-service-fdg`, `<name>-config-fdg`, `<name>-fdg`. Check local clone first, else `gh search repos --owner=Flutter-Global <name>` filtered by `-fdg` / `-config`.
  - **b.2 Shared Chef/Ansible** (non-topology V2): `Flutter-Global/all-chef-fdg` cookbooks or `Flutter-Global/all-ansible-fdg` roles/playbooks named after the service.
  - Precedence: b.1 overrides b.2.
- **VM Evo / Podium** — `fanduel` org, try in order: `sb-<name>-infra`, `<name>-service-deploy`, `<name>-service-infra`, `sb-<name>-deploy`. Local first, else `gh search repos --owner=fanduel <name>` filtered by `infra`/`deploy`/`config`. Not found → unresolved, config extraction partial.

**c)** If cloned, pull it in step 1. If only on GitHub, note the URL. Both per-service `-fdg` and shared Chef/Ansible present → prefer per-service as source of truth.

### Announce

```
Preflight complete:
- Repo: [path/url] — [accessible / NOT FOUND]
- Repo git state: [pulled N / up to date / pull failed — HEAD abc1234 (YYYY-MM-DD)]
- Confluence main page: [found <id> / not found — first run]
- Baseline: [sha:abc1234 / date:YYYY-MM-DD (approximate) / none]
- Changes since baseline: [N commits / none — docs current / first run]
- Files changed: [grouped summary / none / first run]
- Deployment model: [v2 / vm-evo / podium (auto | provided) | ambiguous]
- Config repo: [path / url (not cloned) / not found] — pattern [per-service -fdg / shared Chef-Ansible / VM Evo infra / Podium deploy]
- Config repo git state: [pulled N / up to date / failed / n/a]
- Mode: [create / sweep / report-only]
- Plan: [fresh run / phases X,Y + features F1,F2 / nothing to update]
```

Repo not accessible → stop for that service, report.

---

## Phase 0 — Stack Fingerprint

Discover the actual stack. No assumptions.

```
Glob: **/pom.xml, **/build.gradle*, **/build.sbt, **/package.json
Glob: **/*.proto, **/*.avsc, **/*.thrift
Glob: **/application*.yml, **/application*.properties, **/application*.conf
Read: build files (declared dependencies + versions)
```

| Category | What to look for |
|---|---|
| Language | Java, Kotlin, Scala, TypeScript — version |
| App framework | Spring Boot, Akka HTTP, Pekko, Cougar, Play, bare Netty, Node frameworks |
| Concurrency model | Spring threads, Akka/Pekko actors, Flink operators, Storm topology |
| Messaging | Kafka, Pulsar, RabbitMQ — client library |
| Stream processing | Flink, Storm, Akka/Pekko Streams |
| Databases | Cassandra, MySQL, PostgreSQL, Elasticsearch — ORM/driver |
| HTTP clients | RestTemplate, WebClient, Feign, Akka HTTP client, OkHttp |
| Build tooling | Maven, Gradle, SBT, npm/pnpm |
| Test frameworks | JUnit, ScalaTest, Specs2, TestContainers, Cucumber, Jest |
| Non-obvious | Cougar, internal library versions, custom frameworks |

Output: table technology · version · role. Every row backed by a dependency declaration. Never assume a "standard stack". Note technologies that differ from adjacent services in the same capability area — different framework = different extraction patterns in Phase 2.

---

## Phase 1 — Service Compass

> *"Describe what this service does, what problem it solves, and where it sits in the broader system. Use the initiative documentation as context. State explicitly what it is NOT responsible for. Business terms, no implementation detail."*

Output: 2-paragraph business description; explicit scope boundary (not responsible for); deployment location — environment, cloud, DC (super state / betting state / Outpost), cluster/namespace; link to deploy scripts.

Revise after Phase 2 if contracts reveal a different picture; lock after that unless a factual error is found.

---

## Phase 2 — Contract Inventory

All inputs/outputs extracted from code. Structural backbone. Patterns adapt to the Phase 0 stack.

### Messaging consumers

- **Spring Kafka**: `@KafkaListener`, `@KafkaHandler`
- **Akka/Pekko Streams**: `Consumer.plainSource`, `Consumer.committableSource`, `Consumer.atMostOnceSource`
- **Flink**: `FlinkKafkaConsumer`, `KafkaSource`, `KafkaRecordDeserializationSchema`
- **Storm**: `KafkaSpout`, custom spout `nextTuple`
- **Cougar**: subscription declarations, protobuf bindings in IDD/SDD

```
Topic:          [exact string from annotation/config]
Consumer group: [exact string]
Parallelism:    [concurrency/threads/parallelism]
Offset reset:   [earliest = needs history | latest = real-time only]
Offset commit:  [auto | manual — manual implies at-least-once in code]
Schema:         [proto/avro class, file ref]
Idempotency:    [yes/no — how: dedup key, upsert, conditional write, idempotent producer]
Dead letter:    [DLT topic | MISSING — flag as gap]
DC placement:   [super state | betting state | Outpost]
Evidence:       [file:line]
Open questions: []
```

### Messaging producers

- **Spring Kafka**: `KafkaTemplate.send`, `@SendTo`
- **Akka/Pekko Streams**: `Producer.plainSink`, `Producer.committableSink`, `Producer.flexiFlow`
- **Flink**: `FlinkKafkaProducer`, `KafkaSink`
- **Cougar**: publisher declarations, event type bindings

```
Topic:        [exact string]
Key strategy: [message key and why]
Durability:   [acks: all | 1 | 0]
Idempotent:   [producer idempotency enabled?]
Schema:       [proto/avro class, file ref]
DC placement: [super state | betting state | Outpost]
Evidence:     [file:line]
```

### API / service interfaces

- **Spring MVC/WebFlux**: `@RestController`, `@GetMapping`, `@PostMapping`, `@RequestMapping`
- **Akka/Pekko HTTP**: `Route`, `path()`, `get {}`, `post {}`
- **Cougar**: IDD/SDD service definitions, operation descriptors, `.wsdl`/`.xml` bindings
- **gRPC**: `.proto` service definitions, `@GrpcService`

Per endpoint: path, method, request/response type, auth, sync vs async, evidence. Also capture **APIs consumed** (HTTP clients, gRPC stubs): target service, base URL/config key, purpose.

### Database access

- **Spring Data Cassandra**: `@Table`, `@PrimaryKey`, `@PrimaryKeyColumn`, `CassandraRepository`
- **Phantom DSL (Scala)**: table objects, column declarations
- **Plain CQL**: `PreparedStatement`, `SimpleStatement`, CQL strings
- **JPA**: `@Entity`, `@Repository`, `@Query`
- **JOOQ**: `dslContext.select`, table/field refs
- **Elasticsearch**: `ElasticsearchRepository`, `RestHighLevelClient`, `SearchRequest`

```
Store:          [Cassandra | MySQL | ES | ...]
Table/Index:    [exact name]
Partition key:  [drives the access pattern]
Clustering key: [ordering, if Cassandra]
TTL:            [value — transient | none — permanent]
Access pattern: [read | write | read-write]
Write pattern:  [upsert | insert | delete | conditional]
Evidence:       [file:line]
```

### Scheduled triggers

Spring `@Scheduled` / `TaskScheduler`; Akka/Pekko `scheduleAtFixedRate` / `Timers`; Flink window triggers / `TimerService`; cron expressions in config.

### Stream processing topology (Flink/Storm/Akka Streams)

Source → transform → sink operators (named); state stores (keyed, operator, RocksDB); windowing (tumbling/sliding/session, trigger); checkpointing (interval, exactly-once / at-least-once); parallelism per operator.

### Then produce

- Named high-level description of each distinct flow (input → processing → output) — these feed feature identification.
- Mermaid flow diagram covering all flows, including error paths.
- **DC topology flag**: call out every cross-DC call (latency + data residency implications).

### Contract index

From the same extraction, build a machine-readable index, published on the main page inside an expand section titled exactly `contracts-index` as a YAML code block. Used by Phase 2b on later runs of other services.

```yaml
kafka_consumed:
  - topic: "ppb.stream.fd.instructions.{sport}"   # {sport}/{region}/{env} for parameterised topics
    source_service: FIP
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

---

## Phase 2b — Cross-Service Contact Points

1. List sibling main pages under `parent_page_id`; read each one's `contracts-index` block. Build `{ service → { kafka_consumed, kafka_produced, databases, api_exposed, api_consumed } }`.
2. Also scan the initiative/context doc for service names and topics (Inferred confidence).
3. **Kafka match:** this service's produced topics vs others' consumed (and vice versa). Normalise sport/region/env suffixes to `{sport}`, `{region}`, `{env}`; pattern-level match is enough.
4. **Database match:** shared Cassandra keyspace or host pattern → shared-database edge (strong coupling signal).
5. **API match:** `api_consumed` vs other services' `api_exposed`.
6. Confidence:

| Tier | Condition |
|---|---|
| Confirmed | Both services have a `contracts-index` with matching resource names |
| One-sided | This service names the resource; the other service has no page/index yet |
| Inferred | Only mentioned in context docs |

Output (main page section "Ligações a outros serviços"): Kafka connections table (direction · topic · other service · confidence · evidence), shared databases table, API dependencies, and **unresolved references** — services named in contracts but not yet documented (candidates for the next AutoDocumentation run).

---

## Phase 3 — Architecture, Diagrams & Domain Model

### 3a — C4 Diagrams (Mermaid)

Start at Context, drill down only as far as complexity warrants.

- **C4 Context (always):** upstream sources, this service as `System_Boundary`, downstream consumers, DC annotations. Add every Confirmed / One-sided connection from Phase 2b as a `System`/`System_Ext` node with `Rel()` labelled by topic or API. Inferred ones allowed, commented `// inferred`.
- **C4 Container (multiple deployables):** each deployable (main service, sidecar, Flink job, GSSP instance), protocols (Kafka, HTTP, gRPC, Pulsar), stores (keyspace, DB, index).
- **C4 Component (complex internal modules):** inbound adapters, domain core, outbound adapters.
- **Sequence diagram per flow:** trigger → internals → external calls → output, including error path when it produces a different output. → goes on the feature page.
- **Decision flowchart per flow:** branches on message type, entity state, config flag, error condition. → goes on the feature page.

Compare C4 Context with any existing architecture docs given as context and flag discrepancies.

### 3b — Hexagonal Architecture Map

| Layer | What to look for |
|---|---|
| Inbound ports | Kafka consumers, REST/Cougar controllers, schedulers, Flink sources |
| Domain layer | Services, aggregates, domain events, use cases |
| Outbound ports | Repositories, producers, HTTP clients, Flink sinks |

Flink/Storm: source → transform chain → sink as the equivalent.

**Configuration entry points** — where external config drives behaviour (feature flags, thresholds, routing). Values may live outside the service repo:
- **V2 per-service `-fdg`**: YAML/properties per environment (FD state, UKI brand). Service repo = defaults, `-fdg` = overrides — always check both.
- **V2 shared Chef/Ansible**: cookbook attributes / role variables.
- **VM Evo**: Terraform variables, user-data, SSM parameters, S3 config.
- **Podium**: Helm values, ConfigMaps, Secrets.

### 3c — Domain Model

> *"Identify the domain entities this service manages. For each, describe the states it can be in, what causes transitions, and the business rules that must always hold. No class structure or method signatures."*

Document: entities (name, key fields, business meaning); states; transitions (trigger → state change → output); invariants; aggregates / bounded-context boundaries if DDD-structured.

**Flag any business logic with no documentation source** — logic understandable only by reading code is a risk item.

---

## Phase 4 — Flow Deep Dives

For each flow from Phase 2 — traced from code, not inferred.

**Call chain:** entry point (consumer/endpoint/scheduler) → method → service → repository/producer, with file refs; state changes along the path; external calls and what they return.

**Decisions:**
> *"Describe what the system decides and why, not how the code is structured."*
What choices, on what data, what triggers the non-happy path.

**Error handling:** transient failure (retry, backoff, max attempts); permanent failure (DLT, alerting); poison pill (detection/skip — none → gap); downstream timeout (fallback).

**Idempotency (mandatory for messaging consumers):** safe to replay? mechanism (dedup key, idempotent upsert, check-before-write, conditional update)? what happens on double-processing if it fails?

**Output in business terms:** what the output means to a downstream consumer; which systems/teams depend on it.

After all flows, review Phases 1 and 2 for factual corrections. Apply corrections only — no routine rewrites.

---

## Phase 5 — Deployment Map

> *"Describe how this service is deployed. Not how scripts work mechanically — what happens at each stage, what must be in place first, and what a developer needs to trigger or diagnose a deployment."*

| Model | Where to look | What to extract |
|---|---|---|
| **V2** | `Jenkinsfile`, GoCD YAML, per-service `-fdg` repo OR shared `all-chef-fdg` / `all-ansible-fdg` | GoCD stages, Verum flow, config values / cookbooks, Jenkins triggers. State which config pattern applies. |
| **VM Evo** | Packer templates, Terraform in `fanduel/<name>-*` infra repo, CI config | AMI build pipeline, ASG/EC2 infra, config injection (user-data, SSM, S3) |
| **Podium** | Helm chart in deploy repo, `Dockerfile`, `skaffold.yaml`, CI config | Chart structure, namespace/cluster per env, strategy (rolling/canary/blue-green), ConfigMap/Secret sources, service mesh |

Output: model + config repo; where it runs (cloud, region, DC, cluster/namespace per env); trigger (on merge / manual / scheduled, who can); stages in plain terms; pre-deploy dependencies (infra, upstream services, secrets, certs); env-specific config and where values live; success confirmation (health endpoint, log signals, dashboards); rollback (mechanism, or explicit "none").

---

## Feature Identification

A **feature** = a distinct business capability the service delivers, observable from outside. Derived from Phase 2 flows + Phase 4 deep dives.

- One feature per business outcome, not per class or topic. Several consumers/endpoints feeding the same outcome → one feature.
- Named in business terms ("Market suspension on result", not "ResultConsumer").
- Each feature maps to ≥1 entry point (consumer, endpoint, scheduler) with file:line. No entry point → not a feature; put it in Open Questions.
- Stable `feature-key` (kebab-case) — matches pages across runs regardless of title.
- Typical 3–10 per service; >12 → regroup.
- Record per feature its entry points and the files in its call chain — this is what sweep uses to map changed files → affected feature pages.

---

## Confluence Pages

Before the first write in a run, call `getContentFormatGuide` with `toolName: "createConfluencePage"` (and `"updateConfluencePage"` before updates) and follow it. Write in `html` format.

Evidence convention for every contract claim: **value → evidence (file:line) → open questions**. Example:

```
Topic: catalogue-stream
Consumer group: pcss-catalogue-reader
Schema: CatalogueMessage (protobuf — src/main/proto/catalogue.proto:12)
DC: super state (USE1/USE2)
Idempotency: upsert by entityId (CatalogueRepository.upsert:47)
Dead letter: catalogue-stream-dlt — logged + alert via GAMB
Open questions:
- auto.offset.reset=earliest — intentional? Implies full history bootstrap.
- No retry on downstream HTTP call at EventEnricher:89 — deliberate?
```

### Main service page — title `<ServiceName>`

1. **Warning panel**: "Gerado automaticamente a partir do código por AutoDocumentation. Não final até a checklist de validação ser assinada por alguém com conhecimento do serviço."
2. **Metadata panel**: repo, branch, `source-head: <short-sha> (<YYYY-MM-DD>) [origin/<branch>]`, `generated: <YYYY-MM-DD>`, deployment model, config repo, team, status (`active | deprecated-but-live | deprecated | experimental`; deprecated-but-live → visible deprecation notice). Keep labels `source-head:` and `generated:` exact — sweep parses them.
3. **O que faz / o que não faz** — Phase 1.
4. **Stack** — Phase 0 table.
5. **Arquitetura** — C4 Context (+ Container/Component when produced), DC placement, hexagonal map, configuration entry points.
6. **Topologia** (stream processors only) — source → operators → sink, checkpointing/state backend.
7. **Contratos** — Kafka consumed, Kafka produced, APIs exposed, APIs consumed, data stores, scheduled triggers. Field templates from Phase 2, with evidence.
8. **Ligações a outros serviços** — Phase 2b.
9. **Modelo de domínio** — Phase 3c: entities, states, transitions, invariants, undocumented-logic risks.
10. **Features** — table: feature (current page title), one-line summary, entry point, link to child page.
11. **Deployment** — Phase 5.
12. **Open questions** — table: gap · risk (High/Medium/Low) · source (feature/phase). Systemic patterns (same gap across several features, e.g. DLT missing everywhere) called out explicitly.
13. **Validation checklist** (task list, unchecked):
    - Service purpose statement correct
    - All inputs/outputs captured with real values (not inferred)
    - DC placement correct per contract
    - Architecture diagrams match actual deployment topology
    - Domain entities and states match actual behaviour
    - Each feature page reflects what the service actually does
    - Idempotency assessment accurate for all messaging consumers
    - Deployment description matches current pipeline
    - Cross-service contacts reviewed — no false matches, no missed connections
    - All open questions reviewed — each has an owner or a decision
14. **contracts-index** — expand section with the YAML index.
15. **Notas humanas** — empty on create, human-owned.

### Feature child page — title `<ServiceName> — <Feature name>`

1. **Metadata panel**: `feature-key:`, `source-head:`, `generated:`, entry points (file:line), call-chain files.
2. **Objetivo de negócio** — outcome; which downstream systems/teams depend on it.
3. **Trigger** — what starts it (message, API call, schedule).
4. **Fluxo** — sequence diagram + decision flowchart (Phase 3a) + decisions in business terms (Phase 4).
5. **Contratos envolvidos** — subset of main page contracts used by this feature, with evidence.
6. **Estado / domínio** — entities and transitions this feature touches.
7. **Erros & resiliência** — retry, DLT, poison pill, timeouts, fallback. Missing DLT / poison-pill handling → flag.
8. **Idempotência** — mandatory for messaging-driven features.
9. **Notas para QA** — observable outputs, key edge cases (from decision branches and error paths), dependencies to mock, existing tests found (file refs), testability gaps. Factual, from code.
10. **Open questions** for this feature.
11. **Notas humanas** — empty on create, human-owned.

---

## Write to Confluence (idempotent)

1. Main page: `page_id` from config, else match title under `parent_page_id`. Not found → `createConfluencePage` with `parentId = parent_page_id`.
2. List main page descendants; match feature pages by `feature-key:` in the metadata panel (fallback: title).
3. Per feature:
   - exists + changed → `updateConfluencePage`, `versionMessage: "AutoDocumentation <create|sweep> <YYYY-MM-DD> @ <sha>"`.
   - new → `createConfluencePage` with `parentId` = main page.
   - page exists but feature no longer found in code → **do not delete**. Prepend warning panel "Feature não encontrada no código em <sha> — validar e arquivar manualmente"; list under "Precisa revisão humana".
4. Update the main page last (features table links to final child page ids). Always re-stamp `source-head` and `generated` on the main page and on every page touched.
5. Never touch pages outside the service's main page subtree. Never delete or move pages.

### Human edits (preserve, never overwrite)

- **Match by `feature-key`, never by title** — humans can rename freely.
- **Title:** set only on create; on update keep the current title.
- **Feature display name:** use the current page title everywhere (features table, headings). Code-derived name used only on create.
- **"Objetivo de negócio":** human-owned after creation. On update keep it as-is; if code changes make it look wrong, add a warning panel below ("Código mudou em <sha> — rever objetivo").
- **"Notas humanas":** never written, preserved verbatim.
- **Everything else** is generated — rewritten from code on update.
- If the page's latest version message doesn't start with `AutoDocumentation`, a human edited it since the last run → list under "Precisa revisão humana": "editado manualmente desde último run — secções geradas atualizadas, secções humanas preservadas".

---

## Sweep Mode

Read-only until selection is resolved.

1. **Inventory** — services from config.
2. **Pull** — Preflight step 1 per repo, best-effort, never abort.
3. **Detect drift** — Preflight step 2 per service (baseline from main page `source-head`, date fallback, first run if no page).
4. **Classify** changed files:

| Category | Patterns |
|---|---|
| CONTRACT | `*.proto`, `*.avsc`, `*.thrift` |
| API | `*Controller*`, OpenAPI/Swagger specs |
| KAFKA | `*Consumer*`, `*Producer*`, names with `Kafka`/`topic` |
| DEPS | `pom.xml`, `build.gradle*`, `*.sbt`, `package.json` |
| CONFIG | `application*.{yml,yaml,properties}`, `config/` |
| DEPLOY | CI workflows, `Dockerfile`, Helm/`charts/`, Terraform, Packer |

Adapt to the stack (TypeScript BFF: `src/routes/**`, `src/schemas/**` → API/CONTRACT; `package.json` → DEPS).

   Tier: **NONE** (0 commits) · **MINOR** (only DEPS/CONFIG/DEPLOY/tests) · **SIGNIFICANT** (any CONTRACT/API/KAFKA, or first run).

5. **Select** — interactive: present drifted services grouped by tier, SIGNIFICANT pre-selected, MINOR unticked; writing starts only after confirmation. Unattended: by `auto_tier` — `significant` → SIGNIFICANT only; `all` → SIGNIFICANT + MINOR; `report-only` → none.
6. **Update** — one subagent per selected service (independent page subtrees → safe in parallel). Each runs only the phases and feature pages implicated by its changed files (first run → everything), writes Confluence per the rules above, returns: new `source-head`, pages created/updated/flagged, review flags.
7. **Report** (compact):
   1. Drift table: service · baseline (sha/date/none) · commits · files · categories · tier · selected.
   2. Per updated service: new SHA, pages created/updated (links), stale-feature flags.
   3. **Precisa revisão humana** — aggregated flags from all subagents (missing DLT, unconfirmed idempotency, inferred values, ambiguous deployment model, manual edits, stale features) plus cross-service contradictions (e.g. producer/consumer schema version skew between two services' `contracts-index`).
   4. Failures: pull, missing repo, Confluence auth/permission, config.

Edge handling: pull failure → local HEAD + stale flag, continue; no usable `source-head` → date fallback, stamp on update; missing repo → gap, skip.

---

## Guardrails

- Never invent values — no evidence, no claim → Open Question.
- Never delete or move Confluence pages; never edit outside the service subtree under `parent_page_id`.
- Never overwrite human-owned sections or titles.
- One repo/page failure never blocks the rest of a sweep.
- Pages are drafts of truth until a service owner signs the validation checklist — even a 30-minute review catches subtle errors in business logic and edge cases.

## Open items

- Confluence space + parent page.
- Service repos list.
- Ecosystem-level page (cross-service map, contract registry, systemic open questions) built from all `contracts-index` blocks — not covered yet.
