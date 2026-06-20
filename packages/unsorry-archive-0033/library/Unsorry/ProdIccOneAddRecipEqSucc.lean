import Mathlib

theorem prod_icc_one_add_recip_eq_succ (n : ℕ) (hn : 1 ≤ n) : ∏ k ∈ Finset.Icc 1 n, ((2 * (k : ℚ) + 1) / (2 * (k : ℚ) - 1)) = 2 * (n : ℚ) + 1 := by
  induction n with
  | zero => omega
  | succ m ih =>
    rcases Nat.eq_zero_or_pos m with hm0 | hm0
    · -- m = 0
      subst hm0
      norm_num
    · -- m ≥ 1
      have hm : 1 ≤ m := hm0
      rw [Finset.prod_Icc_succ_top (by omega : 1 ≤ m + 1), ih hm]
      push_cast
      have h2 : (2 * ((m : ℚ) + 1) - 1) ≠ 0 := by
        have : (0:ℚ) ≤ (m:ℚ) := by positivity
        nlinarith
      rw [mul_div_assoc', div_eq_iff h2]
      ring