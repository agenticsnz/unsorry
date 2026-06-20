import Mathlib

theorem prod_icc_one_add_recip_pronic (n : ℕ) (hn : 1 ≤ n) : ∏ k ∈ Finset.Icc 1 n, ((1 : ℚ) + 1 / ((k : ℚ) ^ 2 + 2 * (k : ℚ))) = (2 * ((n : ℚ) + 1)) / ((n : ℚ) + 2) := by
  induction n with
  | zero => omega
  | succ m ih =>
    rcases Nat.eq_zero_or_pos m with h1 | h1
    · -- m = 0
      subst h1
      norm_num
    · -- m ≥ 1
      have hm : 1 ≤ m := h1
      rw [Finset.prod_Icc_succ_top (by omega : 1 ≤ m + 1), ih hm]
      have hk0 : ((m : ℚ) + 1) ^ 2 + 2 * ((m : ℚ) + 1) ≠ 0 := by
        have : (0 : ℚ) ≤ (m : ℚ) := by positivity
        nlinarith [this]
      have hm2 : (m : ℚ) + 2 ≠ 0 := by
        have : (0 : ℚ) ≤ (m : ℚ) := by positivity
        nlinarith [this]
      have hm3 : (m : ℚ) + 3 ≠ 0 := by
        have : (0 : ℚ) ≤ (m : ℚ) := by positivity
        nlinarith [this]
      push_cast
      field_simp
      ring