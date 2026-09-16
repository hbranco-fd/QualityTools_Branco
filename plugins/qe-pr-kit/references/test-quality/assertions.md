# assertions

> **Does it assert the outcome, or only that something exists and nothing threw?**

Playwright makes this failure mode easy to fall into: auto-waiting means a chain of clicks
resolves cleanly and *looks* like a passing test. A spec with no assertion is green as long
as the app does not crash.

**Reaches `theatre`.** A test that cannot express a wrong answer cannot detect one.

---

## solid · playwright-e2e

```ts
await page.getByRole('button', { name: 'Place order' }).click();

await expect(page.getByRole('heading', { name: 'Order confirmed' })).toBeVisible();
await expect(page.getByTestId('order-ref')).toHaveText(/^FD-\d{8}$/);
await expect(page.getByTestId('total-charged')).toHaveText('£42.50');
await expect(page.getByRole('button', { name: 'Place order' })).toBeHidden();
```

**Why:** asserts the state the action was supposed to produce — that it confirmed, what it
confirmed, how much it charged, and that the button is gone so it cannot be double-submitted.
Each assertion fails for a different defect.

---

## solid · playwright-e2e

*Asserting a negative outcome, which is where regressions hide.*

```ts
await page.getByTestId('promo').fill('EXPIRED2024');
await page.getByRole('button', { name: 'Apply' }).click();

await expect(page.getByRole('alert')).toHaveText('This code has expired');
await expect(page.getByTestId('total')).toHaveText('£50.00');   // unchanged
```

**Why:** checks both halves of a rejection — the message shown *and* that the total was left
alone. A bug that displays the error but still applies the discount is caught.

---

## thin · playwright-e2e

```ts
await page.getByRole('button', { name: 'Place order' }).click();
await expect(page.getByTestId('confirmation')).toBeVisible();
```

**Why:** proves the flow reached the confirmation screen, which is a real fact worth having.
But it never looks at it — a confirmation showing the wrong order, a blank reference or a
£0.00 total all pass.

---

## thin · playwright-e2e · matcher looser than the change

*PR changes the order reference format from `FD-12345678` to `FD-2026-12345678`.*

```ts
await page.getByRole('button', { name: 'Place order' }).click();
await expect(page.getByTestId('order-ref')).toContainText('FD-');
```

**Why:** it does assert the reference, so a missing one fails. But `toContainText('FD-')`
holds for the old format, the new one, and a truncated or malformed value alike — the matcher
declines to look at exactly the thing the PR changed. `toHaveText(/^FD-\d{4}-\d{8}$/)` would
make it `solid`.

---

## thin · playwright-e2e · one of several affected outputs

*PR reworks the basket calculation — total, tax line and delivery estimate all derive from it.*

```ts
await expect(page.getByTestId('total')).toHaveText('£42.50');
```

**Why:** the total being right is real evidence and not nothing. But two of the three outputs
the same changed function produces are unasserted, so a wrong tax line or a wrong delivery
estimate ships green.

---

## thin · playwright-component · the new side effect unasserted

*PR adds: the Pay button must disable itself on submit, to stop double charging.*

```tsx
await component.getByRole('button', { name: 'Pay' }).click();
await expect(component.getByText('Processing')).toBeVisible();
```

**Why:** asserts the outcome that already existed before the change, not the one the PR
added. Double submission — the bug this change exists to prevent — passes untouched. Adding
`await expect(component.getByRole('button', { name: 'Pay' })).toBeDisabled()` is the
difference.

---

## weak · playwright-e2e

```ts
await expect(page.getByTestId('order-list')).toBeVisible();
await expect(page.getByRole('row')).toHaveCount(3);
```

**Why:** counts rows without reading them. Three rows of the wrong orders, in the wrong
order, with wrong totals, pass identically. Counting is the assertion people reach for when
the content is precisely what changed.

---

## weak · playwright-e2e

```ts
const text = await page.getByTestId('summary').textContent();
expect(text).toBeTruthy();
expect(text!.length).toBeGreaterThan(10);
```

**Why:** asserts that *some* text was rendered. It also drops out of Playwright's retrying
assertions into a plain snapshot of `textContent`, so it is weaker and racier than it looks.

---

## theatre · playwright-e2e · no assertion at all

```ts
await page.goto('/account/settings');
await page.getByTestId('notifications-toggle').click();
await page.getByRole('button', { name: 'Save' }).click();
```

**Why:** there is no assertion. The spec passes as long as nothing throws — the setting can
silently fail to save and this stays green. The clicks resolving is not evidence; it is
Playwright waiting for elements, not for correctness.

---

## theatre · playwright-e2e · asserting the locator

```ts
await expect(page.getByTestId('error-banner')).toBeTruthy();
expect(page.getByRole('alert')).toBeDefined();
```

**Why:** `getByTestId` returns a locator object, which is always truthy and always defined —
whether or not the element exists on the page. This assertion can never fail. Use
`toBeVisible()`, which actually queries the DOM and retries.

---

## theatre · playwright-e2e · screenshot as the only assertion

```ts
await page.goto('/dashboard');
await expect(page).toHaveScreenshot();
```

**Why:** asserts the page looks like it did when someone last accepted the snapshot. It
cannot say the change is *correct*, only that pixels moved — and it fails constantly for
reasons unrelated to the change (fonts, animation, a date in the header), which is how
snapshots end up blanket-updated without being read.

---

## theatre · playwright-e2e · assertion that cannot observe the change

*PR changes the error message copy and the status code handling.*

```ts
await page.route('**/api/pay', r => r.fulfill({ status: 500 }));
await page.getByRole('button', { name: 'Pay' }).click();
await expect(page.getByRole('alert')).toBeVisible();
```

**Why:** an alert appearing was already true before the change. Both the new copy and the
new status handling are unobserved, so the assertion holds identically before and after the
PR — it is a test of the previous behaviour.

---

# Other stacks

The always-true assertion is the one to memorise: in every binding, a locator is an object,
not a query result. Asserting the object is asserting nothing.

## theatre · playwright-python · asserting the locator

```python
assert page.get_by_test_id("error-banner")
assert page.get_by_role("alert") is not None
```

**Why:** `get_by_test_id` returns a `Locator`, which is always truthy and never `None` —
present or not. Neither line can fail. Use `expect(...).to_be_visible()`, which queries the
DOM and retries.

## theatre · playwright-java · asserting the locator

```java
assertNotNull(page.getByTestId("error-banner"));
assertTrue(page.getByTestId("error-banner") != null);
```

**Why:** `getByTestId` returns a `Locator` object; it is never null. This is the most common
way a Playwright Java test ends up unable to fail. Use
`assertThat(locator).isVisible()` from `com.microsoft.playwright.assertions`.

## theatre · playwright-dotnet · no assertion

```csharp
await Page.GotoAsync("/account/settings");
await Page.GetByTestId("notifications-toggle").ClickAsync();
await Page.GetByRole(AriaRole.Button, new() { Name = "Save" }).ClickAsync();
```

**Why:** no assertion. Green as long as nothing throws; the setting can silently fail to
save.

## weak · playwright-python · counting instead of reading

```python
expect(page.get_by_role("row")).to_have_count(3)
```

**Why:** three wrong rows pass exactly like three right ones, and the rows are what the PR
changed.

## solid · playwright-python

```python
page.get_by_role("button", name="Place order").click()

expect(page.get_by_role("heading", name="Order confirmed")).to_be_visible()
expect(page.get_by_test_id("order-ref")).to_have_text(re.compile(r"^FD-\d{8}$"))
expect(page.get_by_test_id("total-charged")).to_have_text("£42.50")
expect(page.get_by_role("button", name="Place order")).to_be_hidden()
```

**Why:** asserts what the action was supposed to produce, and each assertion fails for a
different defect.

## solid · playwright-java

```java
page.getByRole(AriaRole.BUTTON, new Page.GetByRoleOptions().setName("Place order")).click();

assertThat(page.getByRole(AriaRole.HEADING,
    new Page.GetByRoleOptions().setName("Order confirmed"))).isVisible();
assertThat(page.getByTestId("order-ref")).hasText(Pattern.compile("^FD-\\d{8}$"));
assertThat(page.getByTestId("total-charged")).hasText("£42.50");
```

**Why:** uses Playwright's own retrying assertions rather than `assertEquals` on a captured
string, so it is both a real assertion and a stable one.
