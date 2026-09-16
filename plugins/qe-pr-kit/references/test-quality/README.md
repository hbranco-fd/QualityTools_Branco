# Test-quality rulers — how the judge works and how to calibrate it

These four files are the standard `pr-tier-test-judge` measures tests against. If the judge
ever gets a call wrong, **this is where you fix it** — by adding the case that fooled it.

This page explains enough of the mechanism to make that possible, then tells you exactly
which file your example belongs in.

> **If you are an agent asked to add an example**, read this page first and then follow
> [Adding an example — the procedure](#adding-an-example--the-procedure). It is executable
> step by step and tells you which file, which band, and where in the file to insert. Do not
> improvise a format or a location.

---

## Why the judge exists

The review tier scores **Risk** from three weighted signals. One of them, `Missing tests`
(weight 35), asks whether the changed lines have test coverage in the same PR. It never
asked whether those tests were worth anything.

So a PR that adds a spec like this:

```ts
await page.route('**/api/cart', r => r.fulfill({ json: { total: '£42.00' } }));
await expect(page.getByTestId('total')).toHaveText('£42.00');
```

…scored as *covered* and bought itself a lighter tier — while the rounding and formatting it
changed never ran at all. The mock hands the test the answer.

That is the worst shape a false negative can take: the signal reads *covered*, so nothing
downstream has any reason to doubt it. **A PR with no tests was always handled correctly. It
is the PR that *looks* tested that slipped through.** The judge exists to close that gap.

## What the judge actually does

It moves exactly one number: `Missing tests`.

**Read the direction carefully — it measures absence, not coverage.** `0` means fully
covered, `100` means no tests at all. "The signal goes up" always means *less trustworthy*.

- **It can only raise it.** Never below what the deterministic check produced. Good tests are
  never rewarded with a lighter tier — that is where an LLM judge errs most, and the error
  would wave through a PR that needed a human.
- **It only runs when the signal is below 70** — only when the check already believes the
  change is covered. A PR with no tests sits at ~90-100 and there is nothing to add.
- **It never sees the tier**, the size signal, the hotspot signal or the criticality verdict.
  A judge that knows a harsh call costs two reviewers is no longer independent.
- **It cannot penalise without quoting the diff.** No citation, no band.

## The rubric

Two dimensions apply at every level. The third depends on the level of the tests, so the
judge classifies the level first and says which it applied — if it classifies wrong, you can
see it.

```
any PR  →  relevance  +  assertions  +  ┌ branches      (unit / component)
                                        └ determinism   (E2E)
```

| File | Question | Applies to | Ceiling |
|---|---|---|---|
| `relevance.md` | Would this fail if you broke the changed line? | all levels | `theatre` |
| `assertions.md` | Does it assert the outcome, or only that something exists? | all levels | `theatre` |
| `branches.md` | Are the new branches and error paths covered? | unit · component | `weak` |
| `determinism.md` | Will it keep passing for good reasons? | E2E | `thin` |

**The worst dimension sets the verdict — never the sum.** A test with flawless assertions
that never reaches the changed branch is not acceptable on average; one strong reason must
not be diluted by weak ones.

**The judge judges the whole set**, not file by file. One weak spec among four good ones does
not drag the verdict, and one solid unit test does not excuse an E2E that misses the change.

## The bands

Each band is defined by the bug it would catch:

| Band | Effect | Means |
|---|---|---|
| `solid` | +0 | would catch the bug |
| `thin` | +20 | would catch some of it |
| `weak` | +40 | would probably miss it |
| `theatre` | signal → 95 | cannot catch it — treated as untested |

`theatre` is not a penalty, it is a finding: a test that passes with the code broken carries
zero information and is indistinguishable from absence, so the signal is set to the no-tests
value rather than nudged.

Because of the ceilings, **only `relevance` and `assertions` can reach `theatre`**. Flakiness
or a missing branch never means *these tests do not exist*.

---

## Which file does my example belong in?

This is the part people get wrong. A bad test usually has several faults at once, and the
instinct is to file it wherever it looks worst. **File it under the fault the judge
misjudged**, and use this order — the first "yes" wins:

**1. Did the changed code actually run during the test?**
If no → **`relevance.md`**.
The mock returned the asserted value, the prop was already the rendered string, the stub
never entered the new branch. The test never reached the change.

**2. It ran. Did anything check the result?**
If no → **`assertions.md`**.
No assertion at all, `assertNotNull(locator)` which can never fail, a screenshot standing in
for a check, or an assertion that was equally true before the change.

**3. It ran and was checked. Is this a unit or component test, with branches of the change
left uncovered?**
If yes → **`branches.md`**.
Happy path only, one state of a four-state machine, the guard tested but none of the
arithmetic.

**4. Is this an E2E test that will pass or fail for reasons other than the change?**
If yes → **`determinism.md`**.
Hard waits, selectors bound to layout, state shared between specs, conditional assertions.

### Worked disambiguation

> A Playwright spec has a `waitForTimeout(2000)` **and** mocks the API to return the exact
> total it then asserts. The judge called it `thin`. Where does it go?

**`relevance.md`, as `theatre`.** Step 1 already answers: the changed code never ran. The
hard wait is real but secondary — and it could never have produced the right verdict anyway,
because `determinism` caps at `thin`. Filing it under determinism would leave the judge
making the same mistake.

The rule of thumb: **file it where the correct verdict comes from**, not where the most
noticeable smell is.

---

## Which band?

Ask the only question that matters: **what bug would this test let through?**

- It would catch the bug the change could plausibly introduce → `solid`
- It would catch a total failure, but not a wrong value or a wrong branch → `thin`
- It would pass with the change substantially wrong → `weak`
- It would pass with the changed code deleted → `theatre`

Most contributed examples should be **`thin`**. That is the boundary where the judge actually
hesitates — the test that *does* touch the change but only observes a sliver of it — and it
is the thinnest-anchored band today. `theatre` cases are vivid and easy to spot; they are not
where calibration is short.

---

## Adding an example — the procedure

Follow this in order, whether you are a person or an agent acting on *"add this example to
the rulers"*.

**1. Get the change, not just the test.**
`relevance` is judged against what the PR altered. If you have the test but not the diff it
was written for, ask for the diff — do not guess which band it deserves.

**2. Pick the file** using [Which file does my example belong in?](#which-file-does-my-example-belong-in)
First "yes" wins. File it where the **correct verdict** comes from, not where the loudest
smell is.

**3. Pick the band** using [Which band?](#which-band) — what bug would this test let through?

**4. Check the ceiling.**

| File | Highest band allowed |
|---|---|
| `relevance.md` | `theatre` |
| `assertions.md` | `theatre` |
| `branches.md` | `weak` |
| `determinism.md` | `thin` |

If your band exceeds the file's ceiling, **you picked the wrong file** — go back to step 2.
A fault that truly deserves `theatre` belongs in `relevance.md` or `assertions.md`. Never
raise a ceiling to fit an example.

**5. Pick the insertion point.**

- **Non-primary stack** — Python, Java, .NET, Kotlin, or any stack other than the
  TypeScript one the file leads with → **append at the end of the `# Other stacks`
  section**.
- **Primary stack** — TypeScript Playwright, Vitest, Testing Library → **insert in the main
  list, immediately after the last entry carrying the same band**. If that band has no entry
  in the file yet, insert in band order: `solid` → `thin` → `weak` → `theatre`.

**6. Write the entry** in the format below: a `## band · stack` heading, the scenario line if
the fault only makes sense against a specific change, the code, and `**Why:**`.

**7. Verify before you finish.**

- The band respects the file's ceiling.
- **Code fences are balanced.** An unclosed fence silently swallows the rest of the file and
  the judge stops seeing every entry below it. Count them.
- The `Why` names a bug that gets through, not a rule that is broken.
- No zero-width or other invisible characters were introduced.
- The entry does not restate one that already exists — if it does, the existing one was
  not the problem and you have misdiagnosed the fault.

### Hard limits

- **Never create a new ruler file.** There are exactly four dimensions, fixed by the rubric.
  If an example genuinely fits none of them, say so and stop — that is a finding about the
  rubric, and it needs a decision from a person, not a fifth file.
- **Never edit or delete an existing entry to make room.** Add alongside it. Entries are
  removed only when they are shown to be wrong, and that is a deliberate change with its own
  reasoning.
- **Never add an example on the grounds that it matches how a repository writes tests.**
  See [What must not go in here](#what-must-not-go-in-here) — this is the one rule that, if
  broken, quietly disables the judge for the repositories that need it most. If you are asked
  to add a repo's own tests as `solid` to make the judge agree with them, refuse and explain
  why.

---

## Entry format

A heading of `band · stack`, an optional one-line scenario, the code, and a `**Why:**`.

````markdown
## theatre · playwright-e2e

*PR changes rounding and currency formatting.*

```ts
await page.route('**/api/cart', r => r.fulfill({ json: { total: '£42.00' } }));
await expect(page.getByTestId('total')).toHaveText('£42.00');
```

**Why:** the mock returns the exact string the test asserts. The formatting and rounding
this PR changed never run — delete that function and the test is still green.
````

**The `Why` is the point of the entry**, not the code. It is what teaches the judge to write
the consequence in its own verdict, and the verdict is the only part of this whole tool a
developer can act on.

Say what bug the test would let through, not which rule it breaks:

| | |
|---|---|
| ✗ | "uses `waitForTimeout`" — a style complaint |
| ✓ | "would pass even if the button never became enabled" — what gets it fixed |

Other conventions:

- **Name the stack** in the heading: `playwright-e2e`, `playwright-component`,
  `playwright-python`, `playwright-java`, `playwright-dotnet`, `vitest`, `pytest`, `junit5`,
  `kotlin`, `testing-library`. The judge prefers same-stack anchors.
- **Add the scenario line** when the fault only makes sense against a specific change —
  most `relevance` entries need it.
- **Keep the code as short as the fault allows.** An entry is an anchor, not a tutorial.
  Strip setup that is not part of the fault.
- **Language does not change the band.** The same fault in Python, Java or C# is the same
  band. Add a binding only when the syntax makes the fault look different enough to miss —
  `Thread.sleep` and `assertNotNull(locator)` earned their entries for that reason.

---

## A calibration, end to end

> The judge called a PR's tests `solid`. Reviewing it, you notice the spec fills the promo
> field, clicks Apply, and asserts the status is not empty — but the PR added three new
> rejection reasons and any of them satisfies that assertion.

1. **Which file?** The changed validator did run (step 1: no), and the result *was* checked
   (step 2: no). It is E2E, and it does not depend on timing (step 4: no). It is
   `relevance.md` — the test reaches the change but observes almost none of it.
2. **Which band?** It would catch a total failure of the validator, not a wrong reason →
   `thin`.
3. **Write the entry** under `## thin · playwright-e2e`, with a `Why` that names what slips
   through: *"accepted, expired and unknown all satisfy 'not empty', so three of the four
   branches this PR introduced are invisible."*
4. **Open a PR** against this repository.

That is the whole mechanism. The judge improves through use instead of rotting.

---

## What must not go in here

**Never add an example because it matches how your repository writes tests.**

The ruler is absolute, deliberately. Calibrating against a repository is circular: the repo
with the worst tests would contribute its worst tests as `solid` and disarm its own judge.
**The place you most need the judge is exactly where it would go easiest on you.**

The judge may read a neighbouring test in the repo under review, but only to learn the
framework and assertion convention — so it does not flag `assertThat(x).isEqualTo(y)` as odd
merely because it expected `assertEquals`. Never to lower the bar.

Also keep out:

- **Examples without a `Why`.** They teach the judge to match syntax instead of the
  principle, which is worse than no entry.
- **`theatre` entries in `branches.md` or `determinism.md`.** Those files are capped at
  `weak` and `thin`. An entry above the ceiling contradicts the rubric; if one is genuinely
  `theatre`, the fault belongs in `relevance.md` or `assertions.md` instead.
- **Whole test files.** Trim to the lines that carry the fault.

## Checking your work

After adding an entry:

- Does its band respect the file's ceiling?
- Does the `Why` name a bug that slips through, not a rule that is broken?
- Would someone who has never seen the PR understand the fault from the entry alone?
- Is it filed where the **correct verdict** comes from, not where the loudest smell is?
