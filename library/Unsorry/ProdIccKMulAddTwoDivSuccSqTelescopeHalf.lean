import Mathlib

theorem prod_icc_k_mul_add_two_div_succ_sq_telescope_half (n : ℕ) (hn : 1 ≤ n) :
    ∏ k ∈ Finset.Icc 1 n, ((k : ℝ) * ((k : ℝ) + 2)) / ((k : ℝ) + 1) ^ 2
      = ((n : ℝ) + 2) / (2 * ((n : ℝ) + 1)) := by
  induction n with
  | zero => omega
  | succ m ih =>
    rcases Nat.eq_zero_or_pos m with h1 | h1
    · subst h1
      simp [Finset.Icc_self]
      norm_num
    · have hm : 1 ≤ m := h1
      rw [Finset.prod_Icc_succ_top (by omega : 1 ≤ m + 1), ih hm]
      have hm1 : (m : ℝ) + 1 > 0 := by positivity
      have hm2 : (m : ℝ) + 2 > 0 := by positivity
      have hm3 : (m : ℝ) + 1 + 1 > 0 := by positivity
      push_cast
      field_simp
      ring