import Mathlib

/-- Goal `sum-icc-three-k-add-two-div-triple-consecutive-telescope`: the
telescoping sum `∑_{k=1}^{n} (3k+2)/(k(k+1)(k+2)) = 2 - 1/(n+1) - 2/(n+2)` over
`ℚ`. Induction on `n`. See `library/index/`. -/
theorem sum_icc_three_k_add_two_div_triple_consecutive_telescope (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n,
      ((3 * (k : ℚ) + 2) / ((k : ℚ) * ((k : ℚ) + 1) * ((k : ℚ) + 2)))
      = 2 - 1 / ((n : ℚ) + 1) - 2 / ((n : ℚ) + 2) := by
  induction n with
  | zero => norm_num
  | succ m ih =>
    rw [Finset.sum_Icc_succ_top (by omega : 1 ≤ m + 1), ih]
    have h1 : (m : ℚ) + 1 ≠ 0 := by positivity
    have h2 : (m : ℚ) + 2 ≠ 0 := by positivity
    have h3 : (m : ℚ) + 3 ≠ 0 := by positivity
    push_cast
    field_simp
    ring
