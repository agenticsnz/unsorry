import Mathlib

theorem sum_range_odd_cubes (n : ℕ) : ∑ k ∈ Finset.range n, (2 * k + 1) ^ 3 = n ^ 2 * (2 * n ^ 2 - 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    rcases Nat.eq_zero_or_pos m with hm | hm
    · subst hm; norm_num
    · have h : 1 ≤ 2 * m ^ 2 := by nlinarith
      have h2 : 1 ≤ 2 * (m + 1) ^ 2 := by nlinarith
      nlinarith [Nat.sub_add_cancel h, Nat.sub_add_cancel h2]