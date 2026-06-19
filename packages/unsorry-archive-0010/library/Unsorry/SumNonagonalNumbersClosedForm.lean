import Mathlib

/-- Goal `sum-nonagonal-numbers-closed-form`: `3·∑_{k=0}^{n} k(7k-5) = n(n+1)(7n-4)`
over `ℕ`. Induction on `n`; in the step a `cases` on `m` clears the truncated
`ℕ`-subtraction (`7m-4` is exact once `m ≥ 1`, and vanishes at `m = 0`). See
`library/index/`. -/
theorem sum_nonagonal_numbers_closed_form (n : ℕ) :
    3 * ∑ k ∈ Finset.range (n + 1), k * (7 * k - 5) = n * (n + 1) * (7 * n - 4) := by
  induction n with
  | zero => rfl
  | succ m ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    cases m with
    | zero => rfl
    | succ j =>
      have e1 : 7 * (j + 1) - 4 = 7 * j + 3 := by omega
      have e2 : 7 * (j + 1 + 1) - 5 = 7 * j + 9 := by omega
      have e3 : 7 * (j + 1 + 1) - 4 = 7 * j + 10 := by omega
      rw [e1, e2, e3]
      ring
