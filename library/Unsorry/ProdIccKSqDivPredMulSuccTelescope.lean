import Mathlib

theorem prod_icc_k_sq_div_pred_mul_succ_telescope (n : ℕ) (hn : 2 ≤ n) :
    ∏ k ∈ Finset.Icc 2 n, ((k : ℚ)^2 / ((k - 1) * (k + 1))) = 2 * (n : ℚ) / ((n : ℚ) + 1) := by
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
      have hm0 : (m : ℚ) ≠ 0 := by positivity
      have h1 : (m : ℚ) + 1 ≠ 0 := by positivity
      have h2 : (m : ℚ) + 1 + 1 ≠ 0 := by positivity
      have hsub : ((m : ℚ) + 1) - 1 = (m : ℚ) := by ring
      push_cast
      rw [hsub]
      field_simp