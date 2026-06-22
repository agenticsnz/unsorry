import Mathlib

theorem sum_range_shifted_choose_eq_two_pow_sub_one (n : ℕ) : ∑ k ∈ Finset.range (n + 1), (n + 1).choose (k + 1) = 2 ^ (n + 1) - 1 := by
  have h : ∑ k ∈ Finset.range (n + 2), (n + 1).choose k = 2 ^ (n + 1) := Nat.sum_range_choose (n + 1)
  rw [Finset.sum_range_succ'] at h
  simp at h
  omega