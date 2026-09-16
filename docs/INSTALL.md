# Installing the kits

The kits are distributed as Claude Code plugins through a marketplace called
`quality-tools`. You add the marketplace once, then install whichever kits you
want.

Both steps below are shell commands, not slash commands — run them in a
terminal. The `/plugin ...` equivalents exist inside an interactive `claude`
session, but the CLI works everywhere.

## 1. Add the marketplace

From GitHub:

```bash
claude plugin marketplace add hbranco-fd/QualityTools_Branco
```

Or from a local clone:

```bash
claude plugin marketplace add /absolute/path/to/QualityTools_Branco
```

Either way, installing **copies** the kit into a version-keyed cache at
`~/.claude/plugins/cache/quality-tools/<kit>/<version>/`. A local clone is not
read live — edits to the clone do not reach an installed kit until you bump the
version and update. See [Editing a kit](#editing-a-kit) below.

## 2. Install the kits you need

```bash
claude plugin install qe-ticket-kit@quality-tools
claude plugin install qe-test-plan-kit@quality-tools
claude plugin install qe-test-code-kit@quality-tools
claude plugin install qe-pr-kit@quality-tools
claude plugin install qe-service-kit@quality-tools
```

Installs at **user** scope by default. Take only what matches your work — every
installed skill costs context on every conversation, so a kit you never trigger
is not free.

## 3. Check it worked

```bash
claude plugin list
```

Skills from an installed kit are namespaced by kit — `qe-ticket-kit:<skill-name>`.
The real test is behavioural: say something that should trigger a skill and see
whether it fires.

## Updating

```bash
claude plugin marketplace update quality-tools
claude plugin update qe-ticket-kit@quality-tools
```

Each kit carries its own version and moves independently, so updating the
marketplace does not force every kit forward.

## Editing a kit

Because installing copies into a version-keyed cache, changing a file in the
repository does **not** reach an installed kit on its own. Two ways to close
the gap, depending on whether you are iterating or releasing.

### While iterating

```bash
claude plugin uninstall <kit>@quality-tools
claude plugin install <kit>@quality-tools
```

Uninstalling clears the cache entry, so the install that follows copies whatever
is on disk right now. No version bump needed. Use this while a skill is still
moving.

### When releasing

1. Bump the kit's version in **both** `plugins/<kit>/.claude-plugin/plugin.json`
   and its entry in `.claude-plugin/marketplace.json`. `./scripts/validate.sh`
   fails if they disagree.
2. Commit.
3. `claude plugin marketplace update quality-tools`
4. `claude plugin update <kit>@quality-tools`

This is the path anyone else's machine will take, so a change is not really
shipped until it has a version behind it.

### What does not work

| Command | Result on an edit with no version bump |
| --- | --- |
| `claude plugin update <kit>@quality-tools` | No-op — reports the kit is already at the current version |
| `claude plugin install <kit>@quality-tools` | No-op — reports the kit is already installed |

Both leave the old copy in the cache and say nothing is wrong, which is the
trap: the command succeeds and your edit is still not live.

## Removing a kit

```bash
claude plugin uninstall qe-ticket-kit@quality-tools
```

Removing the marketplace removes access to all of its kits.

## Scope: user or project

Installing at **user** scope makes a kit available in every repository you open.
Installing at **project** scope ties it to one repository and lets you commit
the choice, so teammates who open that repo get the same tooling.

Kits that encode conventions for one service belong at project scope. Kits you
want everywhere — ticket writing, PR review — belong at user scope.

## Troubleshooting

**The marketplace adds but no kits appear.** Check that
`.claude-plugin/marketplace.json` parses and that each `source` path resolves to
a directory containing `.claude-plugin/plugin.json`. Run `./scripts/validate.sh`
from the repository root — it checks exactly this.

**A skill never triggers.** The `description` in its frontmatter is what Claude
matches against. If it does not name the moment and the phrases a user would
actually type, it will stay dormant. See
[CONTRIBUTING.md](CONTRIBUTING.md#the-description-is-the-whole-game).
