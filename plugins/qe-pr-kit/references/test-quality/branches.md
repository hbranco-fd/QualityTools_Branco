# branches

> **Are the new branches and error paths covered, or only the happy path?**

The level-specific dimension for **unit and component** tests. Not applied to E2E — use
`determinism.md` there.

The distinction matters: an E2E spec that skips every validation error is usually making the
*right* call, because that belongs one layer down. A unit test that does the same is leaving
the change untested.

**Capped at `weak` (+40).** Missing a branch never means *these tests do not exist* — the
tests are real, they are simply not where the risk is. It can never reach `theatre`.

---

## solid · vitest unit

*PR adds a clamp, a guard and a rounding rule to `applyDiscount`.*

```ts
describe('applyDiscount', () => {
  it('applies the percentage', () => expect(applyDiscount(1000, 15)).toBe(850));
  it('rounds half up to the penny', () => expect(applyDiscount(999, 15)).toBe(850));
  it('clamps at zero', () => expect(applyDiscount(1000, 150)).toBe(0));
  it('rejects a negative rate', () => expect(() => applyDiscount(1000, -1)).toThrow(RangeError));
  it('passes zero through untouched', () => expect(applyDiscount(0, 15)).toBe(0));
});
```

**Why:** every branch the PR introduced has a case, including the two that only fire on bad
input. The rounding case is chosen at a boundary where a wrong rule gives a different answer.

---

## solid · testing-library component

*PR adds `expired` and `already-used` to the promo field's state machine.*

```tsx
it.each([
  ['valid',        'Code applied'],
  ['expired',      'This code has expired'],
  ['already-used', 'This code has already been used'],
  ['unknown',      'Code not recognised'],
])('renders the %s state', (state, message) => {
  render(<PromoField state={state} />);
  expect(screen.getByRole('alert')).toHaveTextContent(message);
});
```

**Why:** the table covers the whole state machine, so adding a fifth state without a case
is visible as an absence rather than a silent gap.

---

## thin · playwright-component

*Same PR: four states, one covered.*

```tsx
test('renders the error state', async ({ mount }) => {
  const component = await mount(<PromoField state="invalid" />);
  await expect(component.getByRole('alert')).toHaveText('Code not recognised');
});
```

**Why:** one branch of the state machine this PR changed, and it is a real assertion. The
other three — including both states the PR actually added — are untouched.

---

## thin · vitest unit

```ts
it('formats a price', () => {
  expect(formatPrice(4250, 'GBP')).toBe('£42.50');
});
```

**Why:** the happy path holds. The PR also added handling for zero, for negative amounts
(refunds) and for a currency with no minor units (JPY); none of those is exercised, and they
are where formatting rules usually break.

---

## weak · vitest unit

*PR adds declined-card, expired-card and network-failure handling to `submitPayment`.*

```ts
it('submits the payment', async () => {
  const result = await submitPayment(validCard, 4250);
  expect(result.status).toBe('accepted');
});
```

**Why:** the only path exercised is the one where everything works. All three branches the
PR added are error paths, and none is touched — the test covers the code that did not change.

---

## weak · testing-library component

```tsx
it('renders without crashing', () => {
  render(<CheckoutForm />);
  expect(screen.getByRole('form')).toBeInTheDocument();
});
```

**Why:** a smoke test. It proves the component mounts, which was already true before the
change, and enters none of the branches the PR introduced. Common as a placeholder that
never gets replaced.

---

## weak · vitest unit · asserting the mock instead of the branch

```ts
it('retries on failure', async () => {
  const api = vi.fn().mockRejectedValueOnce(new Error()).mockResolvedValue({ ok: true });
  await submitWithRetry(api);
  expect(api).toHaveBeenCalledTimes(2);
});
```

**Why:** it does reach the retry branch, so it is not theatre — but it asserts only that the
function was called twice. The backoff delay, the give-up condition after N attempts and
what the caller finally receives are all unchecked.

---

# Other stacks

Unit and component tests arrive in whatever the repo is written in. The question does not
change: did the branches the PR added get a case?

## solid · pytest

*PR adds a clamp, a guard and a rounding rule to `apply_discount`.*

```python
@pytest.mark.parametrize("amount,pct,expected", [
    (1000, 15, 850),     # applies the percentage
    (999, 15, 850),      # rounds half up to the penny
    (1000, 150, 0),      # clamps at zero
    (0, 15, 0),          # passes zero through
])
def test_apply_discount(amount, pct, expected):
    assert apply_discount(amount, pct) == expected


def test_rejects_a_negative_rate():
    with pytest.raises(ValueError):
        apply_discount(1000, -1)
```

**Why:** every branch the PR introduced has a case, and the rounding case sits on a boundary
where a wrong rule gives a different answer.

## solid · junit5

```java
@ParameterizedTest
@CsvSource({
    "1000, 15, 850",
    " 999, 15, 850",
    "1000, 150, 0",
    "   0, 15, 0",
})
void appliesDiscount(int amount, int pct, int expected) {
    assertEquals(expected, Discounts.apply(amount, pct));
}

@Test
void rejectsANegativeRate() {
    assertThrows(IllegalArgumentException.class, () -> Discounts.apply(1000, -1));
}
```

**Why:** the table makes a missing branch visible as an absent row rather than a silent gap.

## weak · junit5 · happy path only

*PR adds declined-card, expired-card and network-failure handling.*

```java
@Test
void submitsThePayment() {
    var result = service.submitPayment(validCard, 4250);
    assertEquals("accepted", result.status());
}
```

**Why:** the only path exercised is the one where everything works. All three branches the
PR added are error paths and none is touched — this tests the code that did not change.

## weak · pytest · smoke test

```python
def test_renders_without_crashing():
    component = render(CheckoutForm())
    assert component.find_by_role("form")
```

**Why:** proves it mounts, which was already true before the change, and enters none of the
new branches. Also note `assert component.find_by_role(...)` is close to an always-true
assertion — see `assertions.md`.

## thin · kotlin / junit5

*PR adds `EXPIRED` and `ALREADY_USED` to a promo state enum.*

```kotlin
@Test
fun `renders the unknown-code message`() {
    val view = render(PromoField(state = PromoState.UNKNOWN))
    assertThat(view.alertText()).isEqualTo("Code not recognised")
}
```

**Why:** one real assertion on one branch. The two states the PR actually added are both
untested.

## thin · pytest · only the raising branch

```python
def test_raises_on_negative_rate():
    with pytest.raises(ValueError):
        apply_discount(1000, -1)
```

**Why:** covers the guard the PR added, which is genuinely one of the new branches — but
none of the arithmetic branches beside it. Half the change is tested.
