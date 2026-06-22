import Mathlib

theorem prod_icc_one_add_recip_k_sq_sub_one_telescope (n : ℕ) (hn : 2 ≤ n) : (∏ k ∈ Finset.Icc 2 n, (1 + 1 / ((k : ℚ) ^ 2 - 1))) = 2 * (n : ℚ) / (n + 1) := by
  induction n with
  | zero => omega
  | succ m ih =>
    rcases Nat.lt_or_ge m 2 with hm | hm
    · -- m < 2, so m+1 ≤ 2, combined with hn: 2 ≤ m+1, so m+1 = 2, m = 1
      interval_cases m
      · omega
      · -- m = 1, n = 2: product over Icc 2 2 = {2}
        norm_num [Finset.prod_Icc_succ_top]
    · -- m ≥ 2
      rw [Finset.prod_Icc_succ_top (by omega : 2 ≤ m + 1)]
      rw [ih hm]
      have hm0 : (m : ℚ) + 1 ≠ 0 := by positivity
      have hm1 : (m : ℚ) ^ 2 - 1 ≠ 0 := by
        have : (2 : ℚ) ≤ (m : ℚ) := by exact_mod_cast hm
        nlinarith
      have hm2 : ((m : ℚ) + 1) + 1 ≠ 0 := by positivity
      have hmQ : (2 : ℚ) ≤ (m : ℚ) := by exact_mod_cast hm
      have hd : ((m : ℚ) + 1) ^ 2 - 1 ≠ 0 := by nlinarith
      push_cast
      field_simp
      ring