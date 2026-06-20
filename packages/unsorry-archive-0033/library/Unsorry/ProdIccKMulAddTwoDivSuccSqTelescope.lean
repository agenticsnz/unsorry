import Mathlib

theorem prod_icc_k_mul_add_two_div_succ_sq_telescope (n : ℕ) (hn : 1 ≤ n) : (∏ k ∈ Finset.Icc 1 n, ((k : ℚ) * (k + 2)) / (k + 1) ^ 2) = ((n : ℚ) + 2) / (2 * (n + 1)) := by
  induction n with
  | zero => omega
  | succ m ih =>
    rcases Nat.eq_zero_or_pos m with hm0 | hm0
    · -- m = 0, so n = 1
      subst hm0
      norm_num
    · -- m ≥ 1
      have hm : 1 ≤ m := hm0
      rw [Finset.prod_Icc_succ_top (by omega : 1 ≤ m + 1), ih hm]
      push_cast
      have h2 : (m : ℚ) + 1 ≠ 0 := by positivity
      have h3 : (m : ℚ) + 2 ≠ 0 := by positivity
      field_simp
      ring