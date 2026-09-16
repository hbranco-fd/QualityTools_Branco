# Spec Templates

Templates completos por tipo, em formato spec-kit-compatible. Marcar gaps com `[NEEDS CLARIFICATION: pergunta concreta]` em vez de inventar conteúdo.

Princípio transversal: **secções vazias mantêm-se com "N/A" ou `[NEEDS CLARIFICATION: ...]` — nunca removidas**. Spec generators esperam estrutura previsível.

---

## Story de Produto

```markdown
# {Título conciso e descritivo, sem jargão}

> **Type:** Story (Product) | **Status:** Draft | **Spec-ready:** ✅

## Goal

As a {persona específica, não "user" genérico},
I want to {ação concreta},
So that {valor mensurável para utilizador/negócio}.

## Problem

{1-3 frases descrevendo o problema atual. Inclui contexto: porque é problema agora? Que evidência temos?}

## Goals

- {Goal 1 — comportamento observável que será entregue}
- {Goal 2}
- {Goal 3}

## Non-Goals

- {O que esta story explicitamente NÃO faz, mesmo que pareça relacionado}
- {Decisões adiadas para outras stories}

## User Scenarios

### Primary scenario (happy path)
{Numa frase, o caminho principal que o utilizador segue}

### Alternative scenarios
- {Cenário alternativo 1}
- {Cenário alternativo 2}

## Acceptance Criteria

- AC1: Given {pré-condição}, when {ação}, then {resultado observável}.
- AC2: ...
- AC3: ...

(Cobrir: happy path, pelo menos 1 alternativo, comportamento em erro, edge case relevante)

## Edge Cases

1. {Edge case 1 — input limite, estado vazio, concorrência, etc.}
2. {Edge case 2}
3. {Edge case 3}

## Success Criteria (measurable)

- {Métrica 1: ex: "Conversion rate aumenta 5pp face a baseline"}
- {Métrica 2: ex: "Suporte recebe <3 tickets/semana sobre este flow"}

## Out of Scope

- {Coisa que poderia ser confundida como parte desta story mas não é}

## Dependencies

- {Dependência 1: ex: feature flag X em staging, equipa Y entrega API Z}
- N/A se não houver

## Open Questions

- [NEEDS CLARIFICATION: pergunta concreta que precisa de resposta antes de dev começar]
- ...
```

---

## Story Técnica

Diferenças face a Produto:
- **Sem narrativa "As a user..."** — anti-pattern para trabalho de plataforma/débito.
- **Justificação técnica é central** — o equivalente do "valor" para utilizador.
- **Critério de sucesso é métrica antes/depois** ou critério binário verificável.
- **Implementation Hints permitidos** em secção dedicada.

```markdown
# {Título: ação técnica + escopo. Ex: "Migrate consumer to batch processing"}

> **Type:** Story (Technical) | **Status:** Draft | **Spec-ready:** ✅

## Technical Context

{2-3 frases: estado atual, problema que justifica trabalho, sistema(s) afetado(s).}

## Justification

Categoria: {Performance | Tech Debt | Scalability | Security | Observability | DevEx | Reliability}

{Justificação concreta com números sempre que possível:
- Estado atual: {métrica/sintoma}
- Risco de não fazer: {consequência}
- Impacto esperado: {melhoria mensurável}}

## Goals

- {Goal técnico 1}
- {Goal 2}

## Non-Goals

- {O que não vai mudar nesta story}

## Behavior (observable)

{O que muda externamente do ponto de vista de outros sistemas/serviços. Se nada muda externamente, dizer "No external behavior change — internal refactor".}

## Acceptance Criteria

- AC1: {Critério mensurável 1 — ex: "p99 consumer latency <50ms under 10k events/s for 1h in staging"}
- AC2: {Critério 2}
- AC3: {Critério 3}

## Success Criteria (measurable)

| Métrica | Baseline atual | Alvo | Como validar |
|---|---|---|---|
| {ex: latência p99} | {200ms} | {<50ms} | {teste de carga em staging} |
| ... | ... | ... | ... |

## Validation Plan

- {Como validamos antes de prod: testes de carga, comparação A/B, canary, chaos}
- {Como validamos pós-rollout: métricas, alertas, janela de observação}

## Rollout Plan

- Strategy: {feature flag | canary {%} | big bang | gradual}
- Stages: {staging → preprod → prod canary 10% → prod 100%}
- Owner: {quem decide go/no-go}

## Rollback Plan

- Triggers: {gatilhos automáticos ou manuais que disparam rollback}
- Action: {passos concretos do rollback}
- Time-to-rollback target: {ex: <5min}

## Edge Cases

1. {Concorrência / estados de race}
2. {Falha de dependência downstream}
3. {Backwards compatibility com consumers existentes}

## Implementation Hints

> Apenas pistas, não decisões fechadas — spec mantém-se válida mesmo se implementação mudar.

- {Hint 1: ex: "Atual usa Kafka KafkaConsumer.poll síncrono"}
- {Hint 2: ex: "Considerar batch size configurável"}
- {Hint 3}

## Out of Scope

- {Trabalho relacionado mas separado}

## Dependencies

- {Equipas, serviços, infra, feature flags}

## Open Questions

- [NEEDS CLARIFICATION: ...]
```

---

## Task (Produto ou Técnica)

Task é unidade de trabalho mais pequena, normalmente filha de uma Story.

```markdown
# {Título da task — verbo + objeto concreto}

> **Type:** Task ({Product | Technical}) | **Parent:** {Story key se aplicável, senão "Standalone"}

## Goal

{1 frase: o que esta task entrega.}

## Justification

{Para tasks técnicas: porquê agora.
Para tasks produto: ligação ao valor da story-pai.}

## Scope

In scope:
- {Item 1}
- {Item 2}

Out of scope:
- {Item que poderia ser confundido}

## Definition of Done

- DoD1: {Critério verificável 1 — ex: "Build passes, all 47 existing tests green"}
- DoD2: {Critério 2}
- DoD3: {Métricas de não-regressão se aplicável}

## Validation

- {Que testes (unit/integration/contract) são esperados}
- {Coverage mínimo se relevante}
- {Smoke check pós-deploy}

## Implementation Hints

> Apenas para tasks técnicas.

- {Hint 1}

## Risk & Impact

- Blast radius: {single service | cross-service | infra-wide}
- Risk level: {low | medium | high}
- Rollback: {trivial | requires playbook | irreversible — needs extra care}

## Dependencies

- {se houver}

## Open Questions

- [NEEDS CLARIFICATION: ...]
```

---

## Spike / Technical Investigation

Spike sem pergunta é desperdício. Sem timebox arrasta-se.

```markdown
# {Spike: <pergunta concreta>}

> **Type:** Spike | **Timebox:** {ex: 3 days max} | **Parent:** {Story se aplicável}

## Question to Answer

{Uma pergunta concreta. Bom: "Can we use Postgres LISTEN/NOTIFY for our cache invalidation needs at our throughput?". Mau: "Investigate database options".}

## Context

{Porquê precisamos da resposta agora. Que decisão depende disto.}

## Hypotheses to Test

- H1: {ex: "LISTEN/NOTIFY suporta nosso throughput de 5k events/s"}
- H2: {alternativa}

## Approach

- {Passo 1: ex: "POC com 10k events/s sustained"}
- {Passo 2: ex: "Comparar latência vs solução atual"}
- {Passo 3}

## Timebox

**Max duration:** {ex: 3 working days}.
Se ao fim do timebox a pergunta não tiver resposta clara, escrever ADR com o que se sabe e abrir spike de follow-up se necessário.

## Deliverable

Define o que existe no fim do spike. Pelo menos um destes:
- [ ] ADR (Architecture Decision Record) em Confluence
- [ ] POC em repo X (link)
- [ ] Recomendação documentada com prós/contras
- [ ] Benchmark report

## Definition of Done

- DoD1: {ex: "Pergunta tem resposta clara: SIM/NÃO/CONDICIONAL"}
- DoD2: {ex: "Recomendação publicada e revista por 1+ engenheiro sénior"}
- DoD3: {ex: "Próxima ação concreta identificada (story de implementação ou descarte)"}

## Out of Scope

- {Implementação real — spike é só investigação}
- {Decisões fora do escopo da pergunta}

## Open Questions

- [NEEDS CLARIFICATION: ...]
```

---

## Auto-validação

Após gerar a spec, validar contra a **rubrica completa em `_shared/rubric.md`**.

Critérios obrigatórios para considerar spec-ready (resumo — ver rubric.md para pesos e exemplos):
- **Clareza** — título e secções inequívocos
- **Validabilidade** — AC/DoD permitem teste direto (adapta-se ao tipo: feature → AC testáveis; refactor → paridade; observabilidade → artefacto existe)
- **Goals + Non-Goals** preenchidos com itens concretos
- **Edge cases** numerados (mesmo que "considered: none")
- **Dependencies** listadas ou "N/A" justificado
- **Success criteria** mensuráveis
- (Técnicas) **Justificação** com categoria + números
- (Técnicas) **Rollback** com triggers + ação + tempo

**Regra:** se algum critério obrigatório ficar ❌ na rubrica, não entregar como pronto — re-perguntar ou marcar `[NEEDS CLARIFICATION]`.
