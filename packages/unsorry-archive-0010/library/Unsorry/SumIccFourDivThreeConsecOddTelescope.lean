import Mathlib

/-- Goal `sum-icc-four-div-three-consec-odd-telescope`: the telescoping sum
`∑_{k=1}^{n} 4/((2k-1)(2k+1)(2k+3)) = 1/3 - 1/((2n+1)(2n+3))` over `ℝ`. Induction
on `n`. See `library/index/`. -/
theorem sum_icc_four_div_three_consec_odd_telescope (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n,
      (4 : ℝ) / (((2 * k - 1 : ℝ)) * (2 * k + 1) * (2 * k + 3)) =
      1 / 3 - 1 / ((2 * n + 1) * (2 * n + 3)) := by
  induction n with
  | zero => norm_num
  | succ m ih =>
    rw [Finset.sum_Icc_succ_top (by omega : 1 ≤ m + 1), ih]
    have hm : (0 : ℝ) ≤ (m : ℝ) := Nat.cast_nonneg m
    push_cast
    have a1 : 2 * ((m : ℝ) + 1) - 1 ≠ 0 := by intro h; nlinarith
    have a2 : 2 * ((m : ℝ) + 1) + 1 ≠ 0 := by positivity
    have a3 : 2 * ((m : ℝ) + 1) + 3 ≠ 0 := by positivity
    have b1 : 2 * (m : ℝ) + 1 ≠ 0 := by positivity
    have b2 : 2 * (m : ℝ) + 3 ≠ 0 := by positivity
    field_simp
    ring
