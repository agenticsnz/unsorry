import Mathlib

/-- Goal `sum-icc-k-mul-two-k-sub-one-closed-form`:
`6·∑_{k=1}^{n} k(2k-1) = n(n+1)(4n-1)` over `ℕ`. Induction on `n`; a `cases` on `m`
clears the truncated `ℕ`-subtraction (`4m-1`), then `ring`. See `library/index/`. -/
theorem sum_icc_k_mul_two_k_sub_one_closed_form (n : ℕ) :
    6 * ∑ k ∈ Finset.Icc 1 n, k * (2 * k - 1) = n * (n + 1) * (4 * n - 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_Icc_succ_top (by omega : 1 ≤ m + 1), Nat.mul_add, ih]
    cases m with
    | zero => rfl
    | succ j =>
      have e1 : 4 * (j + 1) - 1 = 4 * j + 3 := by omega
      have e2 : 2 * (j + 1 + 1) - 1 = 2 * j + 3 := by omega
      have e3 : 4 * (j + 1 + 1) - 1 = 4 * j + 7 := by omega
      rw [e1, e2, e3]
      ring
