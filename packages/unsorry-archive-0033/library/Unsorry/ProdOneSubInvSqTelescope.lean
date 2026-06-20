import Mathlib

theorem prod_one_sub_inv_sq (n : ℕ) (hn : 2 ≤ n) :
    ∏ k ∈ Finset.Icc 2 n, ((1 : ℚ) - 1 / (k : ℚ) ^ 2) = ((n : ℚ) + 1) / (2 * (n : ℚ)) := by
  induction n with
  | zero => omega
  | succ m ih =>
    rcases Nat.lt_or_ge m 2 with hm | hm
    · -- m < 2, so m+1 = 2 (since 2 ≤ m+1)
      interval_cases m
      · omega
      · -- m = 1, n = 2
        norm_num [Finset.Icc_self]
    · -- m ≥ 2
      rw [Finset.prod_Icc_succ_top (by omega : 2 ≤ m + 1), ih hm]
      have hm0 : (m : ℚ) ≠ 0 := by
        have : (0 : ℕ) < m := by omega
        exact_mod_cast this.ne'
      have hm1 : ((m : ℚ) + 1) ≠ 0 := by positivity
      push_cast
      field_simp
      ring