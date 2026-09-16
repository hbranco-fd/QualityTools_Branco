<!-- MASON TEMPLATE — seed for a repo's knowledge pack. Mason fills every FILL marker
     by analyzing THIS repo, and asks the human to confirm anything uncertain.
     Delete this comment block once filled. -->

# Interpolation Delimiter & Test Fixtures — <!-- FILL: repo name -->

> **Part 1 (the delimiter) is the most error-prone convention — read it first before touching any fixture.**

---

# Part 1 — The variable-interpolation delimiter

<!-- FILL: How does this repo inject runtime values into fixtures/steps/assertions?
     It may be an INVISIBLE private-use character (e.g. U+F8FF / Apple logo, bytes EF A3 BF),
     or a visible token (${...}, <...>, {{...}}, «...»). If you could not confirm the
     mechanism from the code/util, ASK THE HUMAN — do not invent one. -->

- **Delimiter:** <!-- FILL: exact delimiter + Unicode/bytes if invisible -->
- **Syntax:** <!-- FILL: e.g. `<D>index<D>` / `<D>index:default<D>` / `${index}` -->
- **Substitution util:** <!-- FILL: the function/class that performs it -->
- **Seeding:** <!-- FILL: how indexes/values are set (the Background steps or setup) -->

## The three rules
1. **RECOGNIZE** the delimiter wherever it appears — never treat an invisible one as junk/typo/mojibake.
2. **PRESERVE** every occurrence (matched pairs) when editing/reusing. Dropping one breaks substitution silently.
3. **EMIT** it correctly. For an invisible delimiter, never type the glyph — `cp` an existing fixture or insert bytes via `printf`/`python`.

## Insert / verify (fill with the repo's real bytes/token)
```bash
# Find files containing the delimiter:
# FILL: e.g. LC_ALL=C grep -rl $'\xef\xa3\xbf' <test dirs>
# Integrity gate after any edit (paired invisible delimiter -> count must be EVEN):
# FILL: e.g. LC_ALL=C grep -o $'\xef\xa3\xbf' PATH | wc -l
```
<!-- FILL: any gotchas — e.g. placeholders may be UNQUOTED for non-string values, so raw
     templates are intentionally invalid JSON until substituted; don't trust a JSON linter. -->

---

# Part 2 — Test fixtures / data (reuse & naming)

- **Where fixtures live:** <!-- FILL: dir(s) + the resources root the "load payload" step is relative to -->
- **Naming conventions:** <!-- FILL: decode the pattern from real filenames, with examples -->
- **How a test references a fixture:** <!-- FILL: the exact step + path form -->

## Reuse decision
1. **Exact reuse** — an existing fixture already has the fields you need → reference it.
2. **Copy + tweak** — `cp` the closest fixture, change only concrete literals, keep every delimiter intact.
3. **New from scratch** — only if no near-match; author with a visible sentinel then convert to the real delimiter; verify the count is balanced.

## Anatomy of a fixture
<!-- FILL: a short real example (headers/body or equivalent) showing literal vs delimited values -->
