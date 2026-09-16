---
name: story-spec-writer
description: Ajuda a escrever user stories, tasks e spikes estruturadas como specs prontas para spec generators (GitHub spec-kit, Anthropic Superpowers). Output dual — markdown ou criação direta no Jira via MCP. Faz sempre 3-5 perguntas socráticas antes de gerar para extrair contexto, valor e testabilidade. Valida com a rubrica do ticket-quality-analyzer e itera até 80+/100. Usar sempre que o utilizador queira escrever, refazer ou estruturar um ticket — story de produto, story técnica, task ou spike. Triggers EN: "write a story", "draft a ticket", "improve this story", "turn this into a spec", "make this spec-ready". Triggers PT: "escreve uma story", "ajuda-me com esta story", "melhora esta story", "transforma em spec", "redige um ticket", "spec-ready". Ativar agressivamente — se houver hipótese de o utilizador querer ajuda a escrever ou estruturar um ticket de backlog, usar.
---

# Story Spec Writer

Ajuda a escrever stories, tasks e spikes estruturadas como specs — output otimizado para servir de input a spec generators (spec-kit, Superpowers).

Output sempre em **português** quando o utilizador escreve em PT (preferência do Hélder); o spec markdown gerado pode ficar em EN se o utilizador o pedir explicitamente, dado que tickets Jira da equipa APOLLO estão em EN.

## Princípios fundamentais

Estes princípios vêm diretamente das convenções do spec-kit/Superpowers e não devem ser violados:

1. **WHAT/WHY antes de HOW** — o spec descreve comportamento observável e valor. Não tech stack, APIs internas, código. Para *Story Técnica* e *Task Técnica*, hints técnicos são permitidos mas em secção separada (`## Implementation Hints`), nunca misturados com behaviour.

2. **Sem features especulativas** — nada de "talvez precisemos de", "podia ser bom ter", "no futuro". Se não é necessário agora, é Non-Goal ou Out of Scope.

3. **Marcar ambiguidades, não adivinhar** — quando faltar info, escrever `[NEEDS CLARIFICATION: pergunta concreta]` em vez de inventar. Spec-kit espera isto literalmente.

4. **Critérios mensuráveis e testáveis** — "rápido" → "p99 < 200ms"; "bom UX" → "task completion rate > 85%". Cada AC tem de ser verificável sem mais perguntas.

5. **Edge cases numerados** — sempre uma secção com casos limite identificados. Mesmo que vazio, listar "considered: none identified yet".

6. **Scope delimitado** — Non-Goals e Out of Scope explícitos. Sem isto, scope creep é garantido.

## Processo (sempre nesta ordem)

### 1. Detetar modo

- **Gerar do zero:** utilizador descreveu uma ideia/contexto sem texto-fonte. → Vai para passo 2 (perguntas).
- **Melhorar existente:** utilizador colou texto de uma story/ticket. → Lê, identifica gaps, pergunta sobre os mais críticos.
- **Entrevista guiada:** utilizador pede "ajuda-me a escrever" sem fornecer ideia. → Pergunta primeiro o objetivo geral.

### 2. Perguntas socráticas (sempre 3-5)

Não saltar este passo, mesmo que pareça óbvio. Tickets escritos sem perguntas têm sempre gaps.

Usar `ask_user_input_v0` quando disponível (botões > prosa). Selecionar perguntas do banco em `references/socratic-questions.md` adaptadas ao tipo detetado:

- **Story de Produto:** valor para utilizador, persona, métrica de sucesso, edge cases conhecidos, dependências
- **Story Técnica:** problema técnico atual, métrica antes/depois, blast radius, plano de validação, rollback
- **Task:** ligação a story-pai (se aplicável), critério de conclusão, scope delimitado
- **Spike:** pergunta a responder, timebox, entregável, definição de "done"

Para tipos ambíguos, primeira pergunta deve ser **classificadora** (produto vs técnica) — depois adapta.

### 3. Consultar contexto APOLLO (opcional mas recomendado)

Se a story toca um sistema/área que aparece no APOLLO (ex: PCSA-MD, Cassandra, FIP), usar `Atlassian:searchJiraIssuesUsingJql` para buscar 2-3 tickets recentes da mesma área e inferir tom/estilo/convenções da equipa (formato de IDs, nomes de serviços, padrões de AC).

JQL exemplo:
```
project = APOLLO AND text ~ "PCSA-MD" ORDER BY created DESC
```

**Não copiar conteúdo, só estilo.** Cada ticket é único.

### 4. Gerar spec

Ler `references/spec-template.md` para template completo por tipo. Aplicar:

- Estrutura completa spec-kit-style (todas as secções, mesmo vazias com "N/A" ou `[NEEDS CLARIFICATION]`)
- AC em bullets concretos e numerados
- `Implementation Hints` apenas para Story Técnica, Task Técnica, Spike
- Linguagem direta, presente, sem hedging ("must", "will" — não "should", "might")

### 5. Auto-validar com rubrica

Após gerar, aplicar mentalmente a rubrica em `_shared/rubric.md`. Esta é a mesma rubrica usada pela skill `ticket-quality-analyzer` — fonte única da verdade para qualidade de tickets neste plugin.

Calcular score interno. Decisão:

- **Score >= 80 (🟢):** entregar diretamente. Não mostrar score a menos que pedido.
- **Score 50-79 (🟡):** identificar gaps específicos, fazer 1-2 perguntas focadas para resolver. Re-gerar.
- **Score < 50 (🔴):** parar, dizer ao utilizador que falta contexto fundamental, fazer perguntas estruturantes (provavelmente sobre valor/problema, não sobre detalhe).

**Se gaps são genuinamente irresolúveis** (ex: decisão técnica que precisa de stakeholder externo), entregar com `[NEEDS CLARIFICATION: ...]` explícito e flag no fim.

### 6. Output

Por defeito, **markdown pronto a colar no Jira** (formato wiki markup compatível). No fim:

```
---
✅ Spec gerada acima ({tipo} • {natureza se aplicável})
📋 Score interno estimado: {XX}/100 — {se <80, listar 1-3 ações para subir}
🎯 Próximos passos sugeridos:
  • Colar no Jira como descrição do ticket
  • Ou pedir-me para criar diretamente: "cria no Jira"
  • Ou passar a /speckit.specify ou /brainstorming para gerar plan/tasks
```

Se o utilizador pedir "cria no Jira" ou similar, usar `Atlassian:createJiraIssue` com:
- `projectKey: APOLLO`
- `issueTypeName`: mapear tipo (Story → "História" no locale PT, Task → "Tarefa", Bug → "Problema", Spike → "Spike" ou "Technical Spike")
- `summary`: título da spec
- `description`: corpo completo em markdown

## Edge cases

- **Utilizador não responde a uma pergunta socrática:** marcar essa secção com `[NEEDS CLARIFICATION: <pergunta original>]` no spec final. Não inventar.
- **Story gigante (cobre múltiplas camadas/serviços):** flaggar e sugerir split antes de gerar. Oferecer gerar uma das partes ou um overview-spec com sub-stories.
- **Bug em vez de story:** redirecionar para a skill `bug-reporter` se disponível.
- **Spike disfarçado de story:** se a "story" é essencialmente "investigar X", reescrever como Spike e flaggar.
- **Utilizador resiste a Non-Goals:** explicar que sem isso o spec fica vulnerável a scope creep e spec generators perdem-se.

## Anti-patterns que a skill deve evitar

- **AC = repetir a descrição:** AC tem de adicionar especificidade verificável, não parafrasear o resumo.
- **Solução em vez de problema:** se o spec descreve "implementar X usando Y" sem explicar o problema/valor, refazer.
- **Forçar "As a user, I want..." em story técnica:** anti-pattern. Story técnica usa formato direto com justificação técnica.
- **AC vagos:** "deve funcionar bem", "performance adequada" → re-perguntar até ter número/limite/threshold.
- **Implementation no behaviour:** se behaviour menciona stack/framework/lib específica, mover para `Implementation Hints`.

## Referências

**Partilhadas (no _shared/ do plugin):**
- `_shared/rubric.md` — critérios completos por tipo (usado para auto-validação interna)
- `_shared/ticket-types.md` — definições de tipo e natureza (Produto/Técnica)
- `_shared/anti-patterns.md` — red flags e heurísticas a evitar quando se gera

**Específicas desta skill:**
- `references/spec-template.md` — templates spec-kit-style por tipo (Story Produto/Técnica, Task, Spike)
- `references/socratic-questions.md` — banco de perguntas por tipo e fase
- `references/examples.md` — input → output em casos reais
