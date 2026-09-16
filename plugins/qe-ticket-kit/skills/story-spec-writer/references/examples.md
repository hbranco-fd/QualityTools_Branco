# Examples

Input → Output em casos representativos. Cada exemplo mostra:
1. O que o utilizador disse
2. Perguntas que a skill fez
3. Spec gerada (resumida)

---

## Exemplo 1 — Story de Produto a partir de ideia vaga

**Input do utilizador:**
> "Quero adicionar uma feature em que o utilizador vê um aviso quando o saldo está baixo antes de apostar"

**Perguntas socráticas (4):**
- P0: Beneficia utilizador final ou trabalho técnico? → `Utilizador final`
- P1: Persona específica? → `Apostador autenticado`
- P3: Como saber se funcionou em prod? → `Reduzir error rate de "saldo insuficiente" + aumento de deposit conversion`
- P5: O que acontece em caso de erro (saldo unavailable)? → `Mostrar botão Apostar normal — não bloquear se não conseguir verificar`

**Spec gerada (resumida):**

```markdown
# Show low-balance warning before bet placement

> Type: Story (Product) | Status: Draft | Spec-ready: ✅

## Goal
As an authenticated bettor with low balance,
I want to see a deposit prompt instead of attempting a bet that will fail,
So that I can complete a deposit without hitting an "insufficient funds" error.

## Problem
Currently, bettors with balance below a single bet's stake submit bets and only
see "insufficient funds" error after attempting submission. This creates
friction and accounts for [NEEDS CLARIFICATION: % of error events] of failed
submissions.

## Goals
- Detect low-balance state before bet submission attempt
- Surface deposit CTA inline in betslip
- Preserve normal flow when balance is sufficient or unverifiable

## Non-Goals
- Modifying deposit flow itself (separate story)
- Changing balance threshold logic (uses existing config)
- Showing warnings in pre-bet contexts (event page, search, etc.)

## User Scenarios

### Primary scenario
Bettor opens betslip with low balance → sees "Deposit to bet" CTA instead of
"Place bet" button → clicks → enters deposit flow.

### Alternative scenarios
- Balance check times out → fall back to normal "Place bet" button (don't block)
- Balance becomes sufficient mid-session → CTA reverts to "Place bet"

## Acceptance Criteria
- AC1: Given balance < required stake, when betslip opens, then "Deposit to bet"
  CTA appears instead of "Place bet".
- AC2: Given balance check fails or times out (>2s), when betslip opens, then
  default "Place bet" button shows (graceful degradation).
- AC3: Event `low_balance_prompt_shown` emitted with `user_id`, `balance`,
  `required_stake` when CTA renders.
- AC4: Event `low_balance_prompt_clicked` emitted when user taps CTA.

## Edge Cases
1. Balance becomes sufficient mid-session (e.g. via deposit in another tab).
2. Multiple bets in betslip — required stake = sum.
3. Promo credits affecting effective balance.
4. Slow balance API (>2s) — falls back to normal button.

## Success Criteria (measurable)
- "Insufficient funds" error events drop ≥30% within 30 days post-launch.
- Deposit conversion from low-balance prompt ≥5%.

## Out of Scope
- Push notifications about low balance
- Balance warnings outside betslip context
- Auto-deposit features

## Dependencies
- Balance API exposes synchronous check endpoint (existing).
- Deposit flow accepts deeplink parameter (existing).

## Open Questions
- [NEEDS CLARIFICATION: exact threshold for "low" — single bet stake, or configurable buffer?]
- [NEEDS CLARIFICATION: should we show estimated deposit amount needed?]
```

**Pós-output:**
```
✅ Spec gerada acima (Story • Produto)
📋 Score interno estimado: 82/100 — falta resolver 2 [NEEDS CLARIFICATION]
🎯 Próximos passos:
  • Resolver as 2 Open Questions com PO
  • Colar no Jira ou pedir-me "cria no Jira"
  • Passar a /speckit.specify para gerar plan
```

---

## Exemplo 2 — Story Técnica a partir de input já estruturado

**Input do utilizador (já com algum contexto):**
> "Os nossos consumers de Kafka estão a processar mensagens uma a uma de forma síncrona e isso está a limitar o throughput. Quero refactor para batch processing."

**Perguntas socráticas (3 — input já tinha bastante):**
- P2: Estado atual quantificado? → `~200ms p99 por evento, throughput limitado a 5k events/s`
- P4: Critério de sucesso mensurável? → `<50ms p99, ≥20k events/s sustained`
- P7: Estratégia de rollout? → `Canary 10% por consumer group, monitor 1h, depois 100%`

**Spec gerada (resumida):**

```markdown
# Migrate Kafka consumers to batch processing

> Type: Story (Technical) | Status: Draft | Spec-ready: ✅

## Technical Context
Current Kafka consumers process records synchronously one-by-one via
`KafkaConsumer.poll(records=1)`. Per-record handler latency dominates
throughput. Affects [NEEDS CLARIFICATION: which services? all consumers in
APOLLO or specific subset?].

## Justification
**Category:** Performance / Scalability

- Current state: p99 per-event latency 200ms, throughput capped at ~5k events/s
- Risk if not done: Q3 traffic projection of 15k events/s sustained will exceed
  current capacity, causing consumer lag and downstream delays
- Expected impact: <50ms p99, ≥20k events/s sustained — unblocks projected
  growth with margin

## Goals
- Replace per-record processing with bounded-batch processing
- Maintain at-least-once delivery semantics
- Preserve order within partition

## Non-Goals
- Changing consumer group topology
- Migrating to a different streaming platform
- Modifying upstream producers

## Behavior
No external behavior change. Consumers still emit same downstream events with
same payloads. Internal batching is transparent to producers and consumers of
output topics.

## Acceptance Criteria
- AC1: Under sustained load of 10k events/s for 1h in staging, p99 per-batch
  latency <50ms.
- AC2: Throughput sustained ≥20k events/s in staging load test.
- AC3: At-least-once delivery preserved (no message loss, duplicates within
  acceptable bounds per existing SLO).
- AC4: Per-partition order preserved.
- AC5: Existing 47 integration tests continue to pass.

## Success Criteria (measurable)

| Métrica | Baseline | Alvo | Validação |
|---|---|---|---|
| p99 latency | 200ms | <50ms | Datadog dashboard, 24h post-rollout |
| Throughput sustained | 5k/s | ≥20k/s | Load test in staging |
| Consumer lag | varies | <baseline + 10% | Datadog alert |

## Validation Plan
- Pre-prod: load test in staging at 10k/s and 20k/s for 1h each
- Canary: 10% of traffic on one consumer group, monitor 1h
- Full rollout: gradual per consumer group over 2 days
- Post-rollout: 24h observation window, compare metrics

## Rollout Plan
- Strategy: feature flag `kafka_batch_processing` per consumer group
- Stages: staging → preprod 100% → prod canary 10% → prod 100% gradual
- Owner: [NEEDS CLARIFICATION: tech lead da equipa Apollo?]

## Rollback Plan
- Triggers:
  - Consumer lag >2x baseline for >5min
  - Error rate >2x baseline for >5min
  - Any P1/P2 incident attributable to this change
- Action: toggle feature flag off via LaunchDarkly (instant per consumer group)
- Time-to-rollback: <2min

## Edge Cases
1. Partial batch failure — re-process whole batch or only failed records?
2. Consumer rebalance mid-batch — uncommitted offsets handling
3. Slow downstream (e.g. DB write) — backpressure
4. Schema evolution mid-rollout — batches mixing old/new schemas

## Implementation Hints
- Current code: `KafkaConsumer.poll(timeout=100, max_records=1)` in
  ConsumerRunner.java
- Suggested batch size starting point: 100, configurable via env var
- Consider commit-on-batch-success pattern

## Out of Scope
- Producer batching (separate story)
- Consumer rebalancing strategy changes

## Dependencies
- LaunchDarkly feature flag system (existing)
- Datadog dashboards for new batch metrics — needs creation

## Open Questions
- [NEEDS CLARIFICATION: which consumer services in scope — all Apollo or subset?]
- [NEEDS CLARIFICATION: rollout owner / decision maker?]
```

---

## Exemplo 3 — Spike a partir de pergunta direta

**Input do utilizador:**
> "Vamos investigar se conseguimos usar Postgres LISTEN/NOTIFY para invalidar caches em vez de Redis pub/sub"

**Perguntas socráticas (3):**
- P2: Decisão concreta que depende disto? → `Se sim, removemos Redis e simplificamos infra; se não, mantemos`
- P4: Timebox máximo? → `3 working days`
- P5: Entregável? → `ADR + benchmark report`

**Spec gerada (resumida):**

```markdown
# Spike: Can we use Postgres LISTEN/NOTIFY for cache invalidation at our throughput?

> Type: Spike | Timebox: 3 working days | Parent: N/A

## Question to Answer
Can Postgres LISTEN/NOTIFY sustain our cache-invalidation throughput
(currently ~3k notifications/s peak) with acceptable latency (<100ms p99)
without becoming a bottleneck on the primary DB?

## Context
We currently use Redis pub/sub for cache invalidation. Maintaining Redis
adds operational overhead. If Postgres LISTEN/NOTIFY meets our needs, we
can simplify infrastructure by removing Redis from the cache invalidation
path.

## Hypotheses to Test
- H1: LISTEN/NOTIFY sustains 3k notifications/s with <100ms p99 latency
- H2: Connection scaling per listener is feasible without exhausting pool
- H3: Behaviour under DB failover is acceptable (acceptable = brief gap, no message loss > X)

## Approach
1. POC with 1 producer + 5 listener processes against staging Postgres
2. Drive sustained 3k notif/s for 1h, measure p50/p99/p999 latency
3. Test connection limits — how many listeners per DB before degradation?
4. Failover test — kill primary, observe behaviour on listeners
5. Document findings in ADR

## Timebox
**Max duration:** 3 working days. If at end of timebox we don't have a clear
yes/no, write ADR with what is known and create follow-up spike if a specific
sub-question emerged.

## Deliverable
- [ ] ADR in Confluence: "ADR-NNN: Postgres LISTEN/NOTIFY for cache invalidation"
- [ ] Benchmark report with latency/throughput numbers
- [ ] Concrete recommendation: ADOPT / REJECT / CONDITIONAL (with conditions)

## Definition of Done
- DoD1: Question has clear answer (yes / no / conditional with criteria)
- DoD2: ADR published and reviewed by at least 1 senior engineer
- DoD3: Next concrete action identified (implementation story or rejection note)

## Out of Scope
- Actual implementation/migration (would be a follow-up story)
- Investigating other alternatives (NATS, Kafka) — separate spike if rejected
- Changing how application code listens for cache invalidations

## Open Questions
- N/A — spike is itself the answer to the open question.
```

---

## Notas sobre o estilo

Em todos os exemplos:
- Linguagem direta, presente, sem hedging
- Números concretos ou `[NEEDS CLARIFICATION]` — nunca "rápido", "muito", "pouco"
- Non-Goals e Out of Scope **sempre preenchidos** mesmo que com 1-2 itens
- AC numerados (AC1, AC2...) para fácil referência em discussão
- Implementation Hints só quando ajudam — não obrigatório
