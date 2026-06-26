import Mathlib

theorem sum_range_id_mul_choose_eq_half (n : ℕ) : 2 * ∑ k ∈ Finset.range (n + 1), k * Nat.choose n k = n * 2 ^ n := by
  rw [Nat.sum_range_mul_choose]
  rcases n with _ | m
  · simp
  · rw [Nat.succ_sub_one]
    ring
