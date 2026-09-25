# Pipeline run report — TEMPLATE

The shape every pipeline run report takes. Copy it, fill it in, delete nothing.

**Where the filled-in copy goes.** One report per cycle, at
`docs/pipeline-runs/<TICKET>.md` — the ticket key the cycle ran under, nothing else. A cycle that
ran twice is still one report; a second cycle on the same ticket appends to the existing file rather
than creating a second one.

**How to fill it in.** Every field below carries the marker `_fill in_`. Replace each one. A report
still containing that marker is unfinished. Keep the headings and their order exactly as they appear
here: a reader moving between two reports should not have to re-learn the layout.

**The Source column.** Every figure names the artefact it was read from — which file, and where in
it. A figure's provenance differs from run to run: a timestamp may come from the ledger in one cycle
and from a session transcript in the next, because the ledger only records what the conductor
happened to write. A figure with no source is a figure nobody can check.

**When two sources disagree.** Record both values with both sources and do not choose between them.
The report is evidence, not arbitration — silently picking one destroys the only record that there
was a disagreement. Use the *Contested figures* section as the index of where this happened.

**When a figure does not exist.** Do not leave a blank or a dash. Put it in *Not recorded* with the
reason it is unavailable. A blank field and an unrecordable figure look identical on the page and
are not the same thing.

**A caveat about this shape.** It was derived from `ai-pipeline/tools/telemetry.py`'s record and
fitted to one cycle in which Steps 3 and 4 never completed. The Step 3 and Step 4 sections and the
`ai_reviews` field have therefore never been filled from a run that produced them, and may need
adjusting the first time one does.

## Run

| Figure | Value | Source |
|---|---|---|
| Ticket | _fill in_ | _fill in_ |
| Run date | _fill in_ | _fill in_ |
| Timezone | All timestamps in this document are UTC. | — |
| Cycle start | _fill in_ | _fill in_ |
| Cycle end | _fill in_ | _fill in_ |
| Total cycle duration (`total_duration_s`) | _fill in_ | _fill in_ |
| Models across the cycle (`model_summary`) | _fill in_ | _fill in_ |
| Total tokens — input | _fill in_ | _fill in_ |
| Total tokens — output | _fill in_ | _fill in_ |
| Total tokens — cache write | _fill in_ | _fill in_ |
| Total tokens — cache read | _fill in_ | _fill in_ |
| Total cost USD (`total_cost_usd`) | _fill in_ | _fill in_ |
| Cost complete (`cost_complete`) | _fill in_ | _fill in_ |
| Human correction rounds (`human_improvements`) | _fill in_ | _fill in_ |
| AI review rounds (`ai_reviews`) | _fill in_ | _fill in_ |
| Gate reminders sent (`reminders_sent`) | _fill in_ | _fill in_ |
| Conductor consumption (`conductor`, `approximate: true`) | _fill in_ | _fill in_ |

## Steps

One subsection per step, in dispatch order, whether or not the step ran. A step that did not run
keeps its section and states why — omitting it, or reporting zeros, both read as "nothing happened",
which is not the same as "it never started".

Durations here are step time. Time the cycle spent waiting on a person belongs in *Gates* and is
never added into a step's duration. Where a span necessarily encloses a gate, say so on the row.

### Step 1 — ticket-master

| Figure | Value | Source |
|---|---|---|
| Outcome | _fill in_ | _fill in_ |
| Agent id (`agent_ids`) | _fill in_ | _fill in_ |
| Start | _fill in_ | _fill in_ |
| End | _fill in_ | _fill in_ |
| Duration (`duration_s`) | _fill in_ | _fill in_ |
| Model (`models`) | _fill in_ | _fill in_ |
| Messages (`messages`) | _fill in_ | _fill in_ |
| Tokens (`tokens`: input, output, cache write, cache read) | _fill in_ | _fill in_ |
| Cost USD (`cost_usd`, `cost_complete`) | _fill in_ | _fill in_ |
| Quality score | _fill in_ | _fill in_ |

### Step 2 — spec-test-definer

| Figure | Value | Source |
|---|---|---|
| Outcome | _fill in_ | _fill in_ |
| Agent id (`agent_ids`) | _fill in_ | _fill in_ |
| Start | _fill in_ | _fill in_ |
| End | _fill in_ | _fill in_ |
| Duration (`duration_s`) | _fill in_ | _fill in_ |
| Model (`models`) | _fill in_ | _fill in_ |
| Messages (`messages`) | _fill in_ | _fill in_ |
| Tokens (`tokens`: input, output, cache write, cache read) | _fill in_ | _fill in_ |
| Cost USD (`cost_usd`, `cost_complete`) | _fill in_ | _fill in_ |
| Artifacts drafted | _fill in_ | _fill in_ |

### Step 3 — orchestrator-2

| Figure | Value | Source |
|---|---|---|
| Outcome | _fill in_ | _fill in_ |
| Agent id (`agent_ids`) | _fill in_ | _fill in_ |
| Start | _fill in_ | _fill in_ |
| End | _fill in_ | _fill in_ |
| Duration (`duration_s`) | _fill in_ | _fill in_ |
| Model (`models`) | _fill in_ | _fill in_ |
| Messages (`messages`) | _fill in_ | _fill in_ |
| Tokens (`tokens`: input, output, cache write, cache read) | _fill in_ | _fill in_ |
| Cost USD (`cost_usd`, `cost_complete`) | _fill in_ | _fill in_ |
| Commits | _fill in_ | _fill in_ |

### Step 4 — pr

| Figure | Value | Source |
|---|---|---|
| Outcome | _fill in_ | _fill in_ |
| Agent id (`agent_ids`) | _fill in_ | _fill in_ |
| Start | _fill in_ | _fill in_ |
| End | _fill in_ | _fill in_ |
| Duration (`duration_s`) | _fill in_ | _fill in_ |
| Model (`models`) | _fill in_ | _fill in_ |
| Messages (`messages`) | _fill in_ | _fill in_ |
| Tokens (`tokens`: input, output, cache write, cache read) | _fill in_ | _fill in_ |
| Cost USD (`cost_usd`, `cost_complete`) | _fill in_ | _fill in_ |
| Pull request | _fill in_ | _fill in_ |

## Gates

Time the cycle spent waiting on a person, measured apart from step time. `ai-pipeline/tools/
telemetry.py`'s `gate_waits()` emits exactly two, each marked `type: wait`: `spec_review` runs from
Step 2's hand-off to the human until the spec is accepted, and `scheduling` runs from acceptance
until the ticket reaches the dev stage.

| Gate | Type | Start | End | Duration | Source |
|---|---|---|---|---|---|
| `spec_review` | `wait` | _fill in_ | _fill in_ | _fill in_ | _fill in_ |
| `scheduling` | `wait` | _fill in_ | _fill in_ | _fill in_ | _fill in_ |

## Contested figures

Where two surviving artefacts record the same figure differently. One row per disagreement, both
values, both sources, no winner. An empty table here means every figure had a single source, not
that disagreements were resolved.

| Figure | Value A | Source A | Value B | Source B |
|---|---|---|---|---|
| _fill in_ | _fill in_ | _fill in_ | _fill in_ | _fill in_ |

## Not recorded

Figures this cycle cannot produce, and why. Each entry says what is missing and what would have had
to happen for it to exist — so a later reader can tell an unrecordable figure from one somebody
forgot to write down.

| Figure | Why it is unavailable |
|---|---|
| _fill in_ | _fill in_ |
