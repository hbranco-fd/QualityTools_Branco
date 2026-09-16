# Adding to a kit

## Pick the kit first

Ask what the person is holding when they need this. A skill that reads a Jira
ticket goes in `qe-ticket-kit` even if it ends up suggesting tests. A skill that
writes step definitions goes in `qe-test-code-kit` even if it reads the ticket
for context.

If something genuinely belongs in two kits, that is usually a sign it is two
skills wearing one coat. Split it.

## Adding a skill

```bash
KIT=qe-ticket-kit
NAME=my-skill-name

mkdir -p "plugins/$KIT/skills/$NAME"
cp templates/SKILL.md.template "plugins/$KIT/skills/$NAME/SKILL.md"
```

Then:

1. Fill in the template. The directory name and the `name:` in the frontmatter
   must match.
2. Put supporting material in `references/` beside the `SKILL.md` — framework
   docs, worked examples, lookup tables. Keep `SKILL.md` itself to the
   instructions; anything long and stable belongs in a reference file it points
   to.
3. Add a row to that kit's `README.md` table.
4. Bump the kit's version in **both** `plugins/$KIT/.claude-plugin/plugin.json`
   and the matching entry in `.claude-plugin/marketplace.json`.
5. Add a `CHANGELOG.md` entry naming the kit.
6. Run `./scripts/validate.sh`.

## Adding an agent

```bash
cp templates/agent.md.template "plugins/$KIT/agents/my-agent.md"
```

Same steps 3–6 as above.

Reach for an agent over a skill when the work needs its own context window —
a long investigation, a wide search, a task that would otherwise flood the main
conversation with output nobody needs to read. A skill changes how Claude does
something; an agent goes away and comes back with an answer.

## Adding a slash command

```bash
cp templates/agent.md.template "plugins/$KIT/commands/my-command.md"
```

Commands are for things the user invokes deliberately by name. If Claude should
reach for it on its own, make it a skill instead.

## The description is the whole game

For skills, `description:` is the only thing Claude sees when deciding whether
to load your skill. The body might be excellent and never run.

A description that works names four things:

- **What it does** — one clause, concrete
- **The moment** — what the user is doing when they need it
- **Literal triggers** — phrases they would actually type
- **The nudge** — `Prefer triggering over not`, when a miss costs more than a
  false positive

Working in two languages? Put both sets of phrases in. A description that only
lists English triggers will not fire on `avalia este ticket`.

Weak:

```yaml
description: Helps with test plans.
```

Strong:

```yaml
description: >
  Write a functional test plan as Gherkin scenarios, ready to implement.
  Use when the user has a story, ticket, or acceptance criteria and needs to
  know what to test. Trigger on "test plan", "what should we test", "write
  tests for", "derive test cases", or when the user pastes a user story and
  asks for coverage. Also trigger for "plano de testes", "cenários de teste",
  "o que testar". Prefer triggering over not — if there is any chance the user
  wants test scenarios, activate.
```

## Keep skills small

One skill, one job. A skill that has grown to cover three workflows is harder
for Claude to trigger correctly and harder for you to change without breaking
something. When a `SKILL.md` gets long, the usual fix is to move the stable
parts into `references/` and keep the instructions lean — not to keep growing
the file.

## Before you commit

```bash
./scripts/validate.sh
```

It checks that every manifest parses, that marketplace and plugin versions
agree, that every kit on disk is listed in the marketplace, and that every
skill, agent, and command has the frontmatter it needs.

A green run means the structure is sound. It says nothing about whether your
skill triggers or does the right thing — for that, install the kit from a local
clone and try to provoke it with the phrases you put in the description.
