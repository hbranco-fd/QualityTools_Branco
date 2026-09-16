# determinism

> **Will this keep passing for good reasons?**

The level-specific dimension for **E2E**. Not applied to unit or component tests — use
`branches.md` there.

A flaky test is worse than a missing one, and it is worse in a way this tool must care
about: it **counts as coverage** in the deterministic check. It gets retried, then muted,
then deleted — and the coverage it claimed was fiction the whole time. Catching that is
correcting a false negative, not policing style.

**Capped at `thin` (+20).** A `waitForTimeout` is a smell, not a fraud. Flakiness degrades
trust gradually; it never means *these tests do not exist*, so it can never reach `weak` or
`theatre` no matter how many smells are present.

---

## solid · playwright-e2e

```ts
await page.getByRole('button', { name: 'Export' }).click();

await expect(page.getByRole('status')).toHaveText('Export ready');
await expect(page.getByRole('link', { name: 'Download' })).toBeEnabled();
```

**Why:** web-first assertions retry until the real condition holds. Nothing guesses how long
the export takes, so the spec fails when the app is wrong and not when the runner is busy.

---

## solid · playwright-e2e

*Waiting on the event rather than on the clock.*

```ts
const download = page.waitForEvent('download');
await page.getByRole('link', { name: 'Download' }).click();
await expect((await download).suggestedFilename()).toBe('orders-2026-09.csv');
```

**Why:** waits for the thing it needs, then asserts something about it. No timing constant
appears anywhere.

---

## solid · playwright-e2e

*Independent by construction.*

```ts
test('applies a promo code', async ({ page }) => {
  const code = await createPromo();          // this test's own fixture
  await page.goto('/cart');
  await page.getByTestId('promo').fill(code);
  await page.getByRole('button', { name: 'Apply' }).click();
  await expect(page.getByTestId('total')).toHaveText('£45.00');
});
```

**Why:** creates what it needs, so it passes alone, in parallel, sharded, or retried on its
own. The coverage it claims survives any way the suite is run.

---

## thin · playwright-e2e · hard wait

```ts
await page.getByRole('button', { name: 'Export' }).click();
await page.waitForTimeout(3000);
await expect(page.getByRole('link', { name: 'Download' })).toBeEnabled();
```

**Why:** the assertion is right; the wait is a guess. On a slow runner it fails for a reason
that has nothing to do with the change, and the usual repair is a longer sleep — so the
suite gets slower without getting more truthful.

---

## thin · playwright-e2e · brittle selector

```ts
await page.locator('div.grid > div:nth-child(3) > button').click();
await expect(page.locator('.mt-4 > span.text-sm')).toHaveText('Saved');
```

**Why:** bound to layout and utility classes, not to meaning. Any reordering, wrapper or
restyle breaks it and reports a failure where there is no defect. Role- and testid-based
locators survive refactors; these do not.

---

## thin · playwright-e2e · state shared between specs

```ts
test('creates the promo', async ({ page }) => {
  // …creates PROMO-1
});

test('applies the promo', async ({ page }) => {
  await page.getByTestId('promo').fill('PROMO-1');   // depends on the test above
  await expect(page.getByTestId('total')).toHaveText('£45.00');
});
```

**Why:** passes in file order and fails under `--shard`, under parallel workers, or when the
second test is retried alone. The coverage disappears the moment the suite is run any way
but the default.

---

## thin · playwright-e2e · conditional assertion

```ts
const banner = page.getByTestId('promo-banner');
if (await banner.isVisible()) {
  await expect(banner).toHaveText('15% off');
}
```

**Why:** when the banner fails to render — the defect worth catching — the branch is skipped
and the test passes. A test that opts out of asserting whenever the app misbehaves reports
green on exactly the runs that mattered.

---

## thin · playwright-e2e · retries hiding the problem

```ts
// playwright.config.ts
retries: 3,
```

```ts
test('checkout completes', async ({ page }) => { /* … */ });
```

**Why:** not a defect in the spec itself, but three retries on a suite with the smells above
converts a flaky failure into a green run. Worth flagging as `thin` when the PR *raises*
retries alongside the tests it adds — that is the point at which the coverage claim stops
being checkable.

---

# Other stacks

Every binding has a way to sleep, and in each one it means the same thing: the author did
not know what they were waiting for.

## thin · playwright-python · hard wait

```python
page.get_by_role("button", name="Export").click()
page.wait_for_timeout(3000)
expect(page.get_by_role("link", name="Download")).to_be_enabled()
```

**Why:** a guess at how long the export takes. Fails on a slow runner for reasons unrelated
to the change; the usual repair is a bigger number.

## thin · playwright-java · hard wait

```java
page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Export")).click();
Thread.sleep(3000);
assertThat(page.getByRole(AriaRole.LINK,
    new Page.GetByRoleOptions().setName("Download"))).isEnabled();
```

**Why:** `Thread.sleep` inside a Playwright test, where `assertThat(...)` would already
retry on its own. Same guess, and it also blocks the thread.

## thin · playwright-dotnet · hard wait

```csharp
await Page.GetByRole(AriaRole.Button, new() { Name = "Export" }).ClickAsync();
await Task.Delay(3000);
await Expect(Page.GetByRole(AriaRole.Link, new() { Name = "Download" })).ToBeEnabledAsync();
```

**Why:** same fault as `wait_for_timeout` / `Thread.sleep`.

## thin · playwright-python · polling a stale read

```python
for _ in range(10):
    if page.get_by_test_id("status").inner_text() == "Ready":
        break
    page.wait_for_timeout(500)
```

**Why:** a hand-rolled retry loop around a non-retrying read. When it gives up it does not
assert anything — the loop just ends and the test continues, so a permanently stuck status
passes. `expect(...).to_have_text("Ready")` does this correctly in one line.

## solid · playwright-java

```java
page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Export")).click();

assertThat(page.getByRole(AriaRole.STATUS)).hasText("Export ready");
assertThat(page.getByRole(AriaRole.LINK,
    new Page.GetByRoleOptions().setName("Download"))).isEnabled();
```

**Why:** no timing constant anywhere. The assertions retry until the real condition holds.

## thin · playwright-java · brittle selector

```java
page.locator("div.grid > div:nth-child(3) > button").click();
```

**Why:** bound to layout rather than meaning; breaks on any reordering and reports a defect
that is not there.
