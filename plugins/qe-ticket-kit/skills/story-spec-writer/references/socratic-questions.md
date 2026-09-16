# Socratic Questions Bank

Banco de perguntas para a fase de entrevista (3-5 perguntas obrigatórias antes de gerar). Selecionar as mais relevantes para o contexto detetado.

Boas perguntas:
- Têm respostas objetivas, não opinativas vagas
- Forçam o utilizador a explicitar pressupostos
- Resolvem ambiguidades que de outra forma virariam `[NEEDS CLARIFICATION]`

Más perguntas a evitar:
- "Qual é o objetivo?" — demasiado aberta
- "Há mais alguma coisa?" — não estrutura nada
- "Tens AC?" — se tivesse, não pedia ajuda

---

## Pergunta classificadora (sempre primeiro se ambíguo)

**Q0:** Este trabalho beneficia diretamente um utilizador final, ou é trabalho técnico/de plataforma cujo valor é interno (performance, débito, escalabilidade, observabilidade)?
- Opções: `Utilizador final (Produto)` / `Interno técnico (Técnica)` / `Misto — explicar`

Decide entre Story Produto vs Técnica, ou tipo de Task. Quase sempre vale a pena perguntar.

---

## Story de Produto

### Sobre valor e persona

**P1 — Persona específica:**
Quem é o utilizador concreto desta story? (não "users" genérico)
- Opções típicas FanDuel: `Apostador autenticado` / `Apostador não-registado` / `Operador back-office` / `Trader/Risk` / `Outro — descrever`

**P2 — Valor concreto:**
Que problema/atrito remove? Ou que oportunidade desbloqueia?
- Forçar resposta concreta: "evita X", "permite Y", "reduz Z em N%".

**P3 — Métrica de sucesso:**
Como vamos saber, em produção, que esta story funcionou?
- Opções: `Conversion rate` / `Engagement (clicks/views)` / `Error rate / drop-off` / `Suporte (volume de tickets)` / `Revenue` / `Outra — qual`

### Sobre comportamento

**P4 — Happy path em uma frase:**
Descreve o caminho principal numa frase: "Quando X faz Y, vê Z."

**P5 — Cenário de erro:**
O que acontece se a operação principal falhar (timeout, validação, dependência indisponível)?
- Opções: `Mensagem de erro + retry` / `Fallback silencioso` / `Bloquear ação` / `Outro — descrever`

**P6 — Observabilidade:**
Que evento(s) deve emitir para podermos rastrear em produção?
- Opções: `Evento de sucesso (acção completa)` / `Eventos por step` / `Apenas erros` / `Já existem eventos noutra parte`

### Sobre limites e edge cases

**P7 — Casos limite a considerar:**
- `Saldo zero / valores limite` / `Concorrência (mesmo user, múltiplas tabs)` / `Rede instável (offline parcial)` / `Outros estados raros`

**P8 — O que esta story NÃO faz:**
Há funcionalidade adjacente que pode ser confundida com isto mas não é parte desta entrega? (ajuda a definir Non-Goals)

---

## Story Técnica

### Sobre justificação

**P1 — Categoria do problema:**
- Opções: `Performance` / `Tech debt` / `Scalability` / `Security` / `Observability` / `DevEx` / `Reliability`

**P2 — Estado atual quantificado:**
Qual é o sintoma/métrica atual que justifica este trabalho?
- Forçar número: "p99 latência atual = X ms", "build time = Y min", "incidentes/mês = Z".

**P3 — Risco de não fazer:**
O que acontece se mantivermos o status quo nos próximos 3-6 meses?
- Opções: `Incidentes recorrentes` / `Bloqueio de crescimento (capacidade)` / `Custo crescente` / `Risco de segurança` / `Outro`

### Sobre alvo e validação

**P4 — Critério de sucesso mensurável:**
Que métrica antes/depois ou critério binário dirá que o trabalho entregou?
- Forçar: "p99 < X ms sob carga Y", "build < Z min", "0 incidentes da categoria W em 30d".

**P5 — Comportamento externo:**
Esta mudança afeta comportamento observável externamente (APIs, eventos, UI)? Ou é puramente interna?
- Opções: `Sim — comportamento muda` / `Não — refactor sem mudança funcional` / `Sim — mas mantém backwards-compat`

### Sobre risco

**P6 — Blast radius:**
- Opções: `Apenas este serviço` / `Cross-service (múltiplos consumers)` / `Infra-wide` / `Não tenho a certeza`

**P7 — Estratégia de rollout:**
- Opções: `Feature flag + canary` / `Gradual % por % ` / `Big bang com rollback rápido` / `Vou pensar — sugere`

**P8 — Trigger de rollback:**
Que sinal nos faria reverter? (ex: error rate > 2x baseline, latência > X)

---

## Task

### Se filha de Story

**P1 — Story-pai:**
Esta task é parte de que story? (key Jira ou descrição breve)

**P2 — O que entrega:**
Em uma frase, o que está feito quando a task fecha? (output verificável)

### Se standalone (técnica)

**P1 — Justificação para fazer agora:**
Porquê agora e não daqui a 3 meses? (forçar a explicitar urgência)

**P2 — Critério de conclusão verificável:**
Como sabemos que está feita? Não "está feita quando estiver feita" — output concreto.
- Opções: `Build/CI passa` / `Métrica X dentro de threshold Y` / `Artefacto Z criado e revisto` / `Outro`

### Sempre

**P3 — Scope delimitado:**
O que está dentro e fora do âmbito desta task em particular? (sem isto, scope creep garantido)

**P4 — Validação esperada:**
Que tipos de teste são esperados (unit/integration/contract/none)?

**P5 — Risco:**
- Opções: `Trivial — refactor isolado` / `Médio — toca código partilhado` / `Alto — afeta produção`

---

## Spike

### Sobre a pergunta

**P1 — Pergunta concreta:**
Qual é a pergunta específica que o spike vai responder?
- Forçar formato: "Podemos X?" ou "Qual a melhor abordagem para Y?" ou "Vale a pena Z?"
- Rejeitar: "Investigar X", "Estudar Y" (não são perguntas).

**P2 — Decisão que depende:**
Que decisão concreta vai tomar com a resposta deste spike?
- Sem isto, spike é vaidade técnica.

### Sobre âmbito

**P3 — Hipóteses a testar:**
Tens hipóteses iniciais? (Ajuda a focar — spike testa hipóteses, não explora abstractamente.)

**P4 — Timebox máximo:**
Quanto tempo no máximo? (1 day / 3 days / 1 week / outro)
- Forçar resposta — sem isto, spike arrasta-se.

**P5 — Entregável:**
O que fica registado no fim?
- Opções: `ADR / decisão documentada` / `POC em repo` / `Benchmark report` / `Recomendação com prós/contras` / `Múltiplos`

---

## Heurísticas de seleção

Não fazer todas as perguntas — selecionar 3-5 que **mais reduzam ambiguidade** dado o contexto:

- **Input vago / ideia inicial:** focar em P0 (classificadora) + valor/problema + métrica de sucesso
- **Input com solução já delineada:** focar em problema (já está claro o que querem fazer mas não porquê) + edge cases + non-goals
- **Input com AC vagos:** focar em comportamento concreto, casos de erro, observabilidade
- **Input bom mas sem rollback/validação (técnica):** focar em rollback, métricas, blast radius
- **Spike disfarçado de story:** redirecionar — perguntas de Spike

**Sempre incluir pelo menos uma pergunta sobre testabilidade/validabilidade** — é o gap mais comum.
