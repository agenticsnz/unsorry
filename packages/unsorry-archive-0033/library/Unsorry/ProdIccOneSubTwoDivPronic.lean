import Mathlib

theorem prod_icc_one_sub_two_div_pronic (n : ℕ) (hn : 2 ≤ n) : ∏ k ∈ Finset.Icc 2 n, ((1 : ℚ) - 2 / ((k : ℚ) * ((k : ℚ) + 1))) = ((n : ℚ) + 2) / (3 * (n : ℚ)) := by
  induction n with
  | zero => omega
  | succ m ih =>
    rcases Nat.lt_or_ge m 2 with hm | hm
    · -- m < 2 and m+1 ≥ 2 means m = 1
      interval_cases m
      · omega
      · -- m = 1, so n = 2
        norm_num [Finset.Icc_self, Finset.prod_singleton]
    · -- m ≥ 2
      rw [Finset.prod_Icc_succ_top (by omega), ih hm]
      have hm0 : (m : ℚ) ≠ 0 := by positivity
      have hm1 : (m : ℚ) + 1 ≠ 0 := by positivity
      push_cast
      field_simp
      ring