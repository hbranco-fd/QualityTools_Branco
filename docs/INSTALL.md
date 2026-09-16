# Installing the kits

The kits are distributed as Claude Code plugins through a marketplace called
`quality-tools`. You add the marketplace once, then install whichever kits you
want.

## 1. Add the marketplace

From GitHub:

```
/plugin marketplace add fanduel/QualityTools_Branco
```

Or, if you have a local clone (useful while developing a kit):

```
/plugin marketplace add /absolute/path/to/QualityTools_Branco
```

A local clone is read live from disk, so edits show up without republishing.
That makes it the right choice when you are writing a skill, and the wrong
choice when you just want to use one.

## 2. Install the kits you need

```
/plugin install qe-ticket-kit@quality-tools
/plugin install qe-test-plan-kit@quality-tools
/plugin install qe-test-code-kit@quality-tools
/plugin install qe-pr-kit@quality-tools
/plugin install qe-service-kit@quality-tools
```

Take only what matches your work. Every installed skill costs context on every
conversation, so a kit you never trigger is not free.

## 3. Check it worked

Skills from an installed kit appear namespaced by kit:

```
qe-ticket-kit:<skill-name>
```

Ask Claude what skills it has, or start typing `/` to see the commands a kit
brought with it.

## Updating

```
/plugin marketplace update quality-tools
```

Then reinstall or update the individual kits. Each kit carries its own version,
so they move independently — updating the marketplace does not force every kit
forward.

## Removing a kit

```
/plugin uninstall qe-ticket-kit@quality-tools
```

Removing the marketplace itself removes access to all of its kits.

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
