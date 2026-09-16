<!-- MASON TEMPLATE — seed for a repo's knowledge pack. Mason fills every FILL marker
     by analyzing THIS repo, and asks the human to confirm anything uncertain.
     Delete this comment block once filled. -->

# Domain & Framework — <!-- FILL: repo name -->

## 1. Framework architecture (how a component test runs)

- **What a component test is here:** <!-- FILL: black-box? in-process? what's stubbed vs real -->
- **Test framework / library:** <!-- FILL: name + how it's wired (runner, glue/step packages, setup hooks) -->
- **Value/variable mechanism:** <!-- FILL: how runtime values are seeded and interpolated (link to Part 1 of placeholder-and-fixtures) -->
- **Inputs/outputs a test drives:** <!-- FILL: queues/topics/HTTP/DB the tests produce to and assert on -->
- **Suites & tags:** <!-- FILL: the suite classes/configs + how tags map to them -->

## 2. How to run the tests

<!-- FILL: exact commands — Makefile targets / npm scripts / mvn/gradle / pytest, plus any
     Docker/infra to bring up first, and how to run a single feature/tag. Verify these exist. -->

## 3. Domain model (what the tests assert)

<!-- FILL: the entities/hierarchy and the key business concepts the tests exercise, at the level a
     test author needs (e.g. create/update/delete lifecycles, inheritance/overrides/defaults,
     state machines, id/URN schemes). Map each concept to how it appears as a Given (setup) and
     a Then (assertion). Ground this in the repo's own docs/README; ASK the human for domain
     context that isn't derivable from the code. -->
