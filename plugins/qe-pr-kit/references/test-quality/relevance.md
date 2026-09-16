# relevance

> **Would this test fail if you broke the changed line?**

The load-bearing dimension. A test can be beautifully written and still prove nothing about
this PR, because it never reaches the code that changed.

This dimension absorbs over-mocking. Mocking the network in a front-end test is **correct**,
not a defect — you are isolating the UI on purpose. The theatre is a mock that returns the
exact shape the test then asserts, with none of the changed code doing work in between.

**Reaches `theatre`.** A test that cannot fail when the change is broken is
indistinguishable from no test at all.

---

## solid · playwright-e2e

*PR changes the discount calculation in `cart-total.ts`.*

```ts
await page.route('**/api/cart', r => r.fulfill({
  json: { items: [{ price: 1000, qty: 2 }], discountPct: 15 },
}));
await page.goto('/cart');
await expect(page.getByTestId('total')).toHaveText('£17.00');
```

**Why:** the mock supplies *inputs*, not the answer. The multiplication, the discount and
the currency formatting this PR touched all run between the fixture and the assertion.
Change the rate, the rounding or the symbol and this fails.

---

## solid · playwright-component

*PR changes how `PriceTag` derives its display string from a minor-units value.*

```tsx
const component = await mount(<PriceTag amountMinor={4250} currency="GBP" />);
await expect(component).toContainText('£42.50');
```

**Why:** the prop is the raw input the changed function consumes. The derivation under
change stands between the input and the assertion.

---

## thin · playwright-e2e

*PR changes validation on the promo-code field — accept, expired, already-used, unknown.*

```ts
await page.getByTestId('promo').fill('SAVE10');
await page.getByRole('button', { name: 'Apply' }).click();
await expect(page.getByTestId('promo-status')).not.toBeEmpty();
```

**Why:** it does reach the changed validator, and a total failure of it would be caught. But
`accepted`, `expired` and `unknown` all satisfy "not empty" equally, so three of the four
branches the PR introduced are invisible to it.

---

## thin · playwright-e2e

*PR changes rounding from half-up to banker's rounding in `cart-total.ts`.*

```ts
await page.route('**/api/cart', r => r.fulfill({
  json: { items: [{ price: 1000, qty: 2 }], discountPct: 10 },
}));
await page.goto('/cart');
await expect(page.getByTestId('total')).toHaveText('£18.00');
```

**Why:** the changed rounding really does run — the fixture supplies inputs, not the answer.
But £18.00 is the result under both the old rule and the new one. Only a half-penny case
tells them apart, and this fixture never produces one. It would catch the function being
deleted; it would not catch the rule being wrong, which is the entire change.

---

## thin · playwright-component

*PR changes two stages of the same pipeline: the odds normaliser and the renderer.*

```tsx
const component = await mount(<OddsList odds={alreadyNormalised} />);
await expect(component.getByTestId('odds-0')).toHaveText('5/2');
```

**Why:** the renderer this PR changed runs, so this is not theatre. The normaliser — the
other half of the same change — is bypassed by handing the component data that is already
normalised. Half the diff is unobserved, and the mount looks thorough.

---

## thin · playwright-e2e

*PR adds an express-delivery option and reworks how the estimate is derived to fit it.*

```ts
await page.goto('/checkout');                       // express flag off by default
await expect(page.getByTestId('delivery-estimate')).toHaveText('3-5 days');
```

**Why:** the reworked derivation does run on the standard path, so a total breakage would be
caught. But the express branch — the reason the rework happened, and where the risk sits — is
behind a flag this test never turns on.

---

## weak · playwright-e2e

*PR changes the contents of the checkout summary.*

```ts
await page.goto('/checkout');
await expect(page.getByTestId('summary')).toBeVisible();
```

**Why:** the container renders before the changed code fills it. Every line inside could be
wrong, stale or blank and this still passes — it proves routing works, not the change.

---

## weak · playwright-e2e

*PR changes which items are eligible for express delivery.*

```ts
await page.goto('/checkout');
await expect(page.getByTestId('delivery-options')).toBeVisible();
await expect(page.getByRole('radio')).toHaveCount(2);
```

**Why:** counting the options never looks at them. The eligibility rule this PR rewrote
decides *which* two appear; two wrong options pass exactly like two right ones.

---

## theatre · playwright-e2e

*PR changes rounding and currency formatting.*

```ts
await page.route('**/api/cart', r => r.fulfill({ json: { total: '£42.00' } }));
await expect(page.getByTestId('total')).toHaveText('£42.00');
```

**Why:** the mock returns the exact string the test asserts. The formatting, rounding and
conversion this PR changed never run — delete that function entirely and the test is still
green. It asserts its own fixture.

---

## theatre · playwright-component

*PR changes how `PriceTag` derives the displayed string.*

```tsx
const component = await mount(<PriceTag display="£42.00" />);
await expect(component).toContainText('£42.00');
```

**Why:** the prop is already the rendered string, so the derivation under change is bypassed
completely. Same fault as the E2E case above, one layer down.

---

## theatre · playwright-e2e

*PR changes the retry behaviour of the order submission.*

```ts
await page.route('**/api/orders', r => r.fulfill({ status: 200, json: { ok: true } }));
await page.getByRole('button', { name: 'Place order' }).click();
await expect(page.getByText('Order confirmed')).toBeVisible();
```

**Why:** the mock always succeeds on the first call, so the retry path this PR added is
never entered. The test covers the one scenario in which the change is irrelevant. To be
`solid` it would have to fail the first call and succeed the second.

---

# Other stacks

The fault is identical in every Playwright language; only the syntax moves. Judge by what
the mock supplies, never by how it is written.

## theatre · playwright-python

```python
page.route("**/api/cart", lambda route: route.fulfill(json={"total": "£42.00"}))
page.goto("/cart")
expect(page.get_by_test_id("total")).to_have_text("£42.00")
```

**Why:** same fault as the TypeScript case — the fixture is the answer. The formatting the
PR changed is bypassed.

## theatre · playwright-java

```java
page.route("**/api/cart", route -> route.fulfill(
    new Route.FulfillOptions().setBody("{\"total\":\"£42.00\"}")));
page.navigate("/cart");
assertThat(page.getByTestId("total")).hasText("£42.00");
```

**Why:** the stubbed body already carries the formatted string. Nothing under change runs
between the stub and the assertion.

## solid · playwright-java

```java
page.route("**/api/cart", route -> route.fulfill(
    new Route.FulfillOptions().setBody("{\"items\":[{\"price\":1000,\"qty\":2}],\"discountPct\":15}")));
page.navigate("/cart");
assertThat(page.getByTestId("total")).hasText("£17.00");
```

**Why:** the stub supplies inputs. The discount and formatting run in between, so a wrong
rate or a wrong rounding rule fails the test.

## theatre · playwright-dotnet

```csharp
await Page.RouteAsync("**/api/cart", route => route.FulfillAsync(
    new() { Json = new { total = "£42.00" } }));
await Expect(Page.GetByTestId("total")).ToHaveTextAsync("£42.00");
```

**Why:** as above. `Json = new { total = "£42.00" }` hands the test the value it then
asserts.

## solid · playwright-python · forcing the changed branch

*PR adds retry-on-5xx to the order submission.*

```python
calls = {"n": 0}

def handler(route):
    calls["n"] += 1
    route.fulfill(status=500) if calls["n"] == 1 else route.fulfill(json={"ok": True})

page.route("**/api/orders", handler)
page.get_by_role("button", name="Place order").click()

expect(page.get_by_text("Order confirmed")).to_be_visible()
assert calls["n"] == 2
```

**Why:** the first call fails on purpose, so the retry branch the PR added is the only way
this can reach the confirmation. Delete the retry and the test goes red.
