import Mathlib

/-- Goal `sum-nonagonal-closed-form`: `3·∑_{k=0}^{n} (7k²-5k) = n(n+1)(7n-4)` over
`ℕ`. Induction on `n`; in the step a `cases` on `m` isolates the truncated
`ℕ`-subtraction `7m-4`, and `zify` (with the relevant `≤` facts) clears the rest
before `ring`. See `library/index/`. -/
theorem sum_nonagonal_closed_form (n : ℕ) :
    3 * ∑ k ∈ Finset.range (n + 1), (7 * k ^ 2 - 5 * k) = n * (n + 1) * (7 * n - 4) := by
  induction n with
  | zero => rfl
  | succ m ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    cases m with
    | zero => rfl
    | succ j =>
      have h1 : 4 ≤ 7 * (j + 1) := by omega
      have h2 : 5 * (j + 1 + 1) ≤ 7 * (j + 1 + 1) ^ 2 := by nlinarith
      have h3 : 4 ≤ 7 * (j + 1 + 1) := by omega
      zify [h1, h2, h3]
      ring
