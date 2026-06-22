import Mathlib

theorem prod_icc_succ_add_three_div_self_eq_binom_shift (n : ℕ) :
    ∏ k ∈ Finset.Icc 1 n, ((k : ℚ) + 3) / (k : ℚ)
      = ((n : ℚ) + 1) * ((n : ℚ) + 2) * ((n : ℚ) + 3) / 6 := by
  induction n with
  | zero => norm_num
  | succ m ih =>
    rw [Finset.prod_Icc_succ_top (by omega), ih]
    push_cast
    have hm : (m : ℚ) + 1 ≠ 0 := by positivity
    field_simp
    ring