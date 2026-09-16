<!-- MASON TEMPLATE — seed for a repo's knowledge pack. Mason fills every FILL marker
     by analyzing THIS repo, and asks the human to confirm anything uncertain.
     Terminology varies: "steps" may be bindings/glue/step-defs. Map concepts, don't
     force names. Delete this comment block once filled. -->

# Steps & Scenario Patterns — <!-- FILL: repo name -->

> Reuse-first authoring reference. Part 1 = the reusable step/binding catalog; Part 2 = scenario shapes to copy.

## Reuse hierarchy — reuse SCENARIOS *and* steps (stop at the first level that works)
1. **Behaviour already tested** → nothing to add.
2. **Just a new field / small variation → extend an EXISTING scenario** (assertion row + fixture field, `Examples` row if an Outline). No new scenario/step — most common case.
3. **New scenario** from the closest existing shape, existing steps only.
4. **New feature/spec file** — only if none suitable exists.
5. **Steps: reuse → compose → parameterize.**
6. **New step — last resort**, thin, in the right existing module, delegating to framework utilities; document *why*.

---

# Part 1 — Step / binding catalog

- **Framework & runner:** <!-- FILL: e.g. Cucumber-JVM/JUnit5, cucumber-js, pytest-bdd, behave, SpecFlow… + how tags select suites -->
- **Step-definition location & style:** <!-- FILL: dir/package + annotation/decorator style (@Given / Given("...") / @given / [Given]) -->

## Framework-provided steps (reuse FIRST)
<!-- FILL: the generic steps the framework/library gives (publish/consume/HTTP/assert/seed/wait…),
     as actually used in features. Table: | step | purpose |. If none, say so. -->

## Project steps (per file/class)
<!-- FILL: enumerate the repo's own reusable steps grouped by file/class, with a one-line purpose
     and reuse hint each. This is the primary reuse catalog — be exhaustive. -->

---

# Part 2 — Scenario patterns

## Universal test rhythm
<!-- FILL: the canonical Given/When/Then skeleton this repo uses (with a real example),
     including any mandatory boilerplate (e.g. inspection-suppression comment) and the tag line. -->

## Conventions
- **Tags:** <!-- FILL: the tag taxonomy actually used (router/feed/concern/entity or the repo's equivalent) + tags to AVOID copying -->
- **Assertions:** <!-- FILL: how results are asserted (data tables / matchers / JSONPath …), how absence/empty is expressed -->
- **Outlines:** <!-- FILL: is Scenario Outline + Examples used? when to prefer it -->

## Most reusable scenario templates
<!-- FILL: 8–12 representative scenarios a new author would copy, each pointing to a real file
     that exists in THIS repo. Group by module/domain area. -->
