import Mathlib

theorem sum_range_compositions_count_eq_two_pow (n : ℕ) : ∑ k ∈ Finset.range (n + 1), n.choose (k - 1) = 2 ^ n := by
  rcases n with _ | m
  · decide
  · rw [Finset.sum_range_succ']
    simp only [Nat.zero_sub, Nat.choose_zero_right, Nat.add_sub_cancel]
    have : ∑ k ∈ Finset.range (m + 1), (m + 1).choose k = 2 ^ (m + 1) - 1 := by
      have h := Nat.sum_range_choose (m + 1)
      rw [Finset.sum_range_succ, Nat.choose_self] at h
      omega
    rw [this]
    have : 1 ≤ 2 ^ (m + 1) := Nat.one_le_two_pow
    omega