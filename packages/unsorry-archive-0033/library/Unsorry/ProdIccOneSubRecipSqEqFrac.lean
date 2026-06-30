import Mathlib

theorem prod_icc_one_sub_recip_sq_eq_frac (n : ℕ) (hn : 2 ≤ n) : ∏ k ∈ Finset.Icc 2 n, (((k : ℚ) ^ 2 - 1) / (k : ℚ) ^ 2) = ((n : ℚ) + 1) / (2 * (n : ℚ)) := by
  induction n, hn using Nat.le_induction with
  | base => norm_num
  | succ n hn ih =>
    rw [Finset.prod_Icc_succ_top (by omega), ih]
    have hn0 : (n : ℚ) ≠ 0 := by positivity
    have hn1 : (n : ℚ) + 1 ≠ 0 := by positivity
    push_cast
    field_simp
    ring