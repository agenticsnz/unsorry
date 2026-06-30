import Mathlib

theorem prod_icc_succ_sq_div_k_mul_add_two_telescope (n : ℕ) :
    ∏ k ∈ Finset.Icc 1 n, (((k : ℝ) + 1) ^ 2 / ((k : ℝ) * ((k : ℝ) + 2)))
      = 2 * ((n : ℝ) + 1) / ((n : ℝ) + 2) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.prod_Icc_succ_top (by omega : 1 ≤ m + 1), ih]
    push_cast
    have h1 : (m : ℝ) + 2 ≠ 0 := by positivity
    have h2 : (m : ℝ) + 1 + 2 ≠ 0 := by positivity
    have h3 : (m : ℝ) + 1 ≠ 0 := by positivity
    field_simp
    ring