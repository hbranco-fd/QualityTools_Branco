---
name: "ticket-quality-analyzer"
description: "Analisa qualidade de tickets Jira (stories, tasks, bugs, spikes) com lente de QA. Devolve score 0-100, semáforo 🔴🟡🟢, checklist, e sugestões acionáveis. Três modos — (1) on-demand para tickets colados ou JQL, (2) batch agregado, (3) daily report agendado que analisa tickets criados no último dia útil, atualiza Canvas semanal e envia resumo ao Slack (silente se 0 tickets). Usar sempre que o utilizador queira avaliar, rever, auditar ou melhorar tickets, user stories, AC, bug reports ou backlog. Triggers EN: \"review this ticket\", \"is this story good\", \"analyze this backlog\", \"grade these tickets\", \"quality check\", \"DoR check\", \"is this AC testable\", \"audit my tickets\", \"daily report\", \"weekly canvas\". Triggers PT: \"analisa esta story\", \"esta ticket está boa\", \"revê este bug\", \"qualidade dos tickets\", \"está pronto para dev\", \"DoR\", \"critérios de aceitação\", \"relatório diário\", \"canvas semanal\". Ativar agressivamente — se houver hipótese de o utilizador querer feedback de qualidade de tickets, usar."
---

# Ticket Quality Analyzer

Analisa qualidade de tickets Jira com lente de QA. Detecta tipo automaticamente e aplica critérios relevantes. Output sempre em **português** (Hélder preferência).

## Processo

### 1. Obter o(s) ticket(s)

Três modos de input:

**A. Texto/JSON colado** — processar diretamente o que o utilizador colou.

**B. Jira MCP (Atlassian connector)** — se o utilizador referir ticket keys (ex: `PROJ-123`) ou JQL, usar ferramentas Atlassian disponíveis:
- `Atlassian:getJiraIssue` para fetch individual
- `Atlassian:searchJiraIssuesUsingJql` para batch/backlog
- Se connector não disponível, pedir para colar o conteúdo

**C. Daily report automático** — modo scheduled. Ver secção "Modo Daily Report" abaixo.

Se múltiplos tickets → modo **batch** (análise individual + relatório agregado).

### 2. Detectar tipo e natureza

Identificar **tipo** + **natureza** (produto vs técnica) para ativar critérios relevantes:

**Tipos:**
- **Story** — unidade entregável de valor
- **Task** — trabalho operacional
- **Bug** — defeito
- **Spike/Tech investigation** — research timeboxed

**Natureza** (aplicável a Story e Task):
- **Produto** — valor direto para utilizador final / cliente. Normalmente tem narrativa "As a user...".
- **Técnica** — valor interno (plataforma, performance, débito técnico, escalabilidade, segurança, observabilidade). Valor indireto para utilizador.

**Como distinguir:**
- Se o ticket beneficia utilizador final de forma observável → **Produto**
- Se o ticket beneficia equipa/sistema (reduz tempo de deploy, estabilidade, custo, manutenção) → **Técnica**
- Story técnica NÃO deve forçar narrativa "As a user..." — é anti-pattern. Deve justificar valor técnico concreto.

Se ambíguo, assumir o mais provável e **declarar explicitamente a assunção** no output.

### 3. Aplicar rubrica

Ler `references/rubric.md` para critérios completos e sistema de pontuação. Aplicar **apenas** os critérios que fazem sentido para o tipo detectado — um Spike não precisa de AC testáveis formais; um Bug não precisa de INVEST.

Critérios transversais (sempre avaliar):
- **Clareza** — título e descrição inequívocos
- **Validabilidade (QA lens)** — como validamos que foi entregue? Forma de validação adequada ao tipo (AC testáveis, paridade, métrica, artefacto, etc). Ver rubric.md para matriz.
- **Dependências e riscos** — identificados ou ausentes?
- **Definition of Ready** — tem o mínimo para entrar em dev?

Ver `references/rubric.md` para lista completa, pesos e exemplos.

### 4. Calcular score e semáforo

Score 0-100 baseado nos critérios aplicáveis (ver rubric.md para pesos).

Semáforo:
- 🟢 **Verde (80-100):** pronto ou quase — pequenos ajustes opcionais
- 🟡 **Amarelo (50-79):** utilizável mas com gaps — refinamento recomendado
- 🔴 **Vermelho (0-49):** não pronto — bloquear entrada em sprint

### 5. Output

Usar formato em `references/output-templates.md`. Dois templates:

**Single ticket:**
```
## [KEY] Título
Tipo: Story | Score: 72/100 | 🟡 Amarelo

### ✅ Pontos fortes
- ...

### ⚠️ Issues encontrados
- [Critério] Descrição do problema

### 🎯 Sugestões acionáveis
1. Adicionar AC concreto para caso X
2. ...

### Checklist de critérios
| Critério | Status | Nota |
|---|---|---|
| ... | ✅/⚠️/❌ | ... |
```

**Batch (relatório agregado):** ver template completo em `references/output-templates.md` — inclui distribuição de scores, padrões recorrentes, top gaps, recomendações para a equipa.

## Princípios

1. **Honesto, não suave** — flaggar problemas reais mesmo em tickets que parecem ok à primeira vista. Hélder quer rigor.
2. **Concreto > genérico** — nunca dizer "melhorar descrição"; dizer exatamente o quê falta.
3. **QA lens sempre** — pergunta-chave em cada ticket: *"consigo desenhar testes a partir disto sem fazer mais 5 perguntas?"*
4. **Sem inventar contexto** — se faltar info, listar como gap, não especular.
5. **Shift-left** — sugerir melhorias que apanhem problemas antes de dev começar.

## Modo Daily Report

Quando invocado com trigger de scheduled task (prompt tipo *"daily report"*, *"relatório diário"*, *"executa daily-report"*), a skill:

### 0. Configuração (hardcoded para execução do Hélder)

- **Projeto Jira:** `GRIZZ` (board 22407)
- **Canal Slack:** `C0ARXNT5QC9` (#grizzlies-qa)
- **Timezone:** America/New_York (o Jira e contas da equipa estão em NY)
- **Tipos incluídos:** Story/História, Task/Tarefa, Bug, Spike

> **Nota (legacy):** ficheiros de referência (ex: `references/canvas-workflow.md`) ainda podem mencionar `APOLLO` / board `4078` — são legacy e não foram reescritos. Esta config é a fonte da verdade: usar sempre `GRIZZ` / board `22407`. O cabeçalho do Canvas semanal deve dizer "projeto GRIZZ (board 22407)".

### 1. Determina janela temporal

Regra: **janela = último dia de trabalho** (dias úteis apenas).

| Dia de execução | Janela `created` | Racional |
|---|---|---|
| Terça a sexta | Dia anterior (1 dia útil) | Dia útil anterior |
| Segunda-feira | Sexta-feira anterior (só sexta, não sábado/domingo) | Último dia útil |
| Sábado/domingo | Não executa | Não é dia útil |

**Implementação:** calcular dia de execução; se for segunda, a janela é sexta anterior 00:00 → sexta anterior 23:59. Se for terça-sexta, janela é dia anterior 00:00 → dia anterior 23:59. Sábado/domingo → skip.

Timezone: America/New_York (o Jira e contas da equipa estão em NY).

### 2. Executa JQL

Query (**sem filtro de tipo no JQL** — os nomes de tipo variam PT/EN entre instâncias e um nome inexistente rebenta a query inteira; filtrar tipos na fase de análise):
```
project = GRIZZ
AND created >= "YYYY-MM-DD HH:mm" AND created < "YYYY-MM-DD HH:mm"
ORDER BY created DESC
```

Usar `Atlassian:searchJiraIssuesUsingJql` com esta query. Campos a fetchar: `summary`, `description`, `issuetype`, `priority`, `status`, `created`, `reporter`, `assignee`, `labels`, `components`, `customfield_*` para AC se existir.

**Filtrar tipos na análise (não no JQL):** manter Story/História, Task/Tarefa, Bug/Erro/Problema, Spike. Excluir Epic/Épico, Initiative/Iniciativa e Sub-task/Subtarefa — usar `issuetype.hierarchyLevel == 0` e `issuetype.subtask == false` (independente do idioma do nome). Se, depois de excluir estes, sobrarem 0 tickets → aplicar regra de silêncio (secção 3).

### 3. Se zero tickets → não envia

Condição explícita: **se a JQL (após filtro de tipo na análise) retornar 0 tickets, a skill termina sem enviar nada ao Slack**. Nem mesmo uma mensagem "nada criado ontem". Silêncio é o comportamento correto.

Logar internamente que foi executada e não havia nada.

### 4. Se tickets > 0 → analisa e envia

Aplicar o fluxo standard (detecção de tipo/natureza, rubrica, score, semáforo). Gerar **relatório compacto** (não o formato completo — ver template abaixo) e enviar via Slack MCP.

### 5. Canvas semanal + mensagem Slack

O envio tem **duas partes**: atualizar o Canvas semanal e postar mensagem no canal com link para o Canvas.

Ver `references/canvas-workflow.md` para detalhes completos. Resumo:

**Canvas semanal (um por semana):**
- **Segunda:** criar novo Canvas `Daily Ticket Quality — Week of YYYY-MM-DD` via `Slack:slack_create_canvas`. Inclui secção de tendências (rolling 4 semanas) + análise de sexta.
- **Terça a sexta:** encontrar Canvas da semana atual (via `Slack:slack_search_public` com `creator:@<bot>` + `during:<week>` + filtrar por título) e anexar secção do dia via `Slack:slack_update_canvas` (action=`append`, cronológico).
- **Nunca sobrescrever** — sempre append. Segunda sempre cria novo.

**Mensagem Slack (todos os dias):**
- `Slack:slack_send_message` para `C0ARXNT5QC9`
- Formato compacto (ver template inline abaixo)
- Linka o Canvas da semana no fim

### 6. Template mensagem Slack (compacto, inline no canal)

Objetivo: mensagem **clean**, baixo ruído — só o pulse do dia. O detalhe (gaps, por-tipo, checklists) vive no Canvas, não no canal.

```
📋 **Daily Ticket Quality — {DAY_NAME}, {DATE}**

{N} ticket(s) · 🟢 {X}  🟡 {Y}  🔴 {Z} · média {XX}/100

**⛔ Bloqueadores:** {keys ou "nenhum"}

{Tickets — piores primeiro:}
• [{KEY}](https://fanduel.atlassian.net/browse/{KEY}) {título truncado} — {emoji} {score}/100

Análise detalhada: [Week of {YYYY-MM-DD}]({canvas_url})
```

**Regras do template Slack:**
- **Formatação = markdown standard** (não mrkdwn clássico). O connector `slack_send_message` converte `**negrito**` → negrito Slack. ⚠️ Asterisco simples `*x*` renderiza como **itálico** — nunca usar para bold.
- **Links = markdown standard `[texto](url)`**, nunca `<url|texto>`. Aplica-se aos tickets e ao Canvas.
- **Sem preview de página:** o link "Análise detalhada" usa formato âncora `[Week of ...](url)` — links com texto âncora não fazem unfurl no Slack (só URLs nus fazem). Nunca colar o URL cru.
- **Reduzir ruído — cortar do Slack:** não incluir as secções "Por tipo" nem "Top gaps recorrentes" na mensagem do canal; vivem no Canvas.
- Linha-resumo única: volume + distribuição (🟢🟡🔴) + score médio.
- Truncar títulos a 60 chars.
- Max 5 bloqueadores (se mais, "e mais N…"); se não houver 🔴, escrever "nenhum".
- **Secção "Tickets" lista os tickets do dia**, ordenados por score ascendente (piores primeiro). Se >10, mostrar top 10 piores + linha "_e mais N — ver Canvas_".
- **Link do Canvas sempre na última linha**, sem emoji nem bold — leve, é a âncora do dia.

### 7. Setup necessário (comunicar ao utilizador na primeira execução)

Este modo requer:

1. **Claude Scheduled Task configurada** — o utilizador cria uma task em Claude.ai com schedule (ex: dias úteis às 9h) e prompt tipo:
   > *"Executa a skill ticket-quality-analyzer em modo daily-report."*

2. **Atlassian MCP connector ativo** — para fetch de tickets
3. **Slack MCP connector ativo** — para envio ao canal `C0ARXNT5QC9` (#grizzlies-qa)

Se algum destes faltar na execução, a skill **para, reporta o que falta, e não envia nada silenciosamente**.

### 8. Política de aprovação do Slack

O Slack MCP pode bloquear envios diretos a canais públicos com erro "No approval received". Ordem de fallback:

1. **Tentar `slack_send_message`** primeiro (envio direto).
2. **Se bloqueado:** usar `slack_send_message_draft` — cria draft no Slack para o utilizador aprovar manualmente. Reportar no output do chat que o draft foi criado e precisa de aprovação.
3. **Não tentar enviar múltiplas vezes** se bloqueado — um fallback para draft e terminar.

Canvas (`slack_create_canvas`, `slack_update_canvas`) não são afetados por esta política — executam sem aprovação.

### Assumções deste modo (declarar no primeiro output)

- Âmbito: `project = GRIZZ` (board 22407). Se quiseres restringir a componentes/labels/teams, dizer.
- Timezone: America/New_York
- Canal: `C0ARXNT5QC9`
- Tipos incluídos: Story/História, Task/Tarefa, Bug, Spike
- Janela de sábado/domingo: não executa

## Edge cases

- **Ticket vazio/minimalista:** score baixo automático + lista de campos em falta. Não tentar inferir.
- **Ticket em inglês:** análise em português, mas citações/quotes do ticket mantêm-se no original.
- **Epic/initiative:** avisar que skill é para tickets operacionais; aplicar só critérios de clareza e valor.
- **Ticket já "Done":** análise histórica — útil para retrospetiva, mas flaggar que ação corretiva pode não aplicar.

## Referências

- `references/rubric.md` — critérios completos, pesos, exemplos de bom/mau por tipo
- `references/output-templates.md` — templates de output (single + batch)
- `references/qa-heuristics.md` — heurísticas QA específicas (testabilidade, observabilidade, riscos)
- `references/canvas-workflow.md` — fluxo Canvas semanal (criar segunda, anexar ter-sex, tendências 4 semanas)
