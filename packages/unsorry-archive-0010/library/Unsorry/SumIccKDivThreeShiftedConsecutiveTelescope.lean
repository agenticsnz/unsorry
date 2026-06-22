import Mathlib

open Finset

/-- Goal `sum-icc-k-div-three-shifted-consecutive-telescope`: the telescoping sum
`∑_{k=1}^{n} k/((k+1)(k+2)(k+3)) = 1/4 + 1/(2(n+2)) - 3/(2(n+3))` over `ℝ`.
Induction on `n`. See `library/index/`. -/
theorem sum_icc_k_div_three_shifted_consecutive_telescope (n : ℕ) :
    ∑ k ∈ Icc 1 n, (k : ℝ) / ((k + 1) * (k + 2) * (k + 3))
      = 1 / 4 + 1 / (2 * (n + 2)) - 3 / (2 * (n + 3)) := by
  induction n with
  | zero => norm_num
  | succ m ih =>
    rw [Finset.sum_Icc_succ_top (by omega : 1 ≤ m + 1), ih]
    have h2 : (m : ℝ) + 2 ≠ 0 := by positivity
    have h3 : (m : ℝ) + 3 ≠ 0 := by positivity
    have h4 : (m : ℝ) + 4 ≠ 0 := by positivity
    push_cast
    field_simp
    ring
