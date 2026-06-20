import Mathlib

/-- Goal `sum-icc-two-k-add-one-div-k-sq-succ-sq-telescope`: the telescoping sum
`∑_{k=1}^{n} (2k+1)/(k²(k+1)²) = 1 - 1/(n+1)²` over `ℚ`. Induction on `n`. See
`library/index/`. -/
theorem sum_icc_two_k_add_one_div_k_sq_succ_sq_telescope (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n, (2 * (k : ℚ) + 1) / ((k : ℚ) ^ 2 * ((k : ℚ) + 1) ^ 2)
      = 1 - 1 / ((n : ℚ) + 1) ^ 2 := by
  induction n with
  | zero => norm_num
  | succ m ih =>
    rw [Finset.sum_Icc_succ_top (by omega : 1 ≤ m + 1), ih]
    have h1 : (m : ℚ) + 1 ≠ 0 := by positivity
    have h2 : (m : ℚ) + 2 ≠ 0 := by positivity
    push_cast
    field_simp
    ring
