import Mathlib

open Finset

theorem sum_range_k_mul_choose_mul_four_pow_closed (n : ℕ) : 5 * ∑ k ∈ Finset.range (n + 1), k * n.choose k * 4 ^ k = 4 * n * 5 ^ n := by
  have hbin : ∀ m : ℕ, ∑ j ∈ Finset.range (m + 1), m.choose j * 4 ^ j = 5 ^ m := by
    intro m
    have h := add_pow (4 : ℕ) 1 m
    simp only [one_pow, mul_one, Nat.cast_id] at h
    rw [show (4 : ℕ) + 1 = 5 from rfl] at h
    rw [h]
    apply Finset.sum_congr rfl
    intro j hj
    ring
  cases n with
  | zero => simp
  | succ m =>
    rw [Finset.sum_range_succ']
    simp only [Nat.zero_mul, pow_zero, mul_one, add_zero]
    have key : ∀ j ∈ Finset.range (m + 1),
        (j + 1) * (m + 1).choose (j + 1) * 4 ^ (j + 1)
          = (m + 1) * (4 * (m.choose j * 4 ^ j)) := by
      intro j hj
      have h := Nat.add_one_mul_choose_eq m j
      rw [pow_succ]
      have h2 : (j + 1) * (m + 1).choose (j + 1) = (m + 1) * m.choose j := by
        rw [h, Nat.mul_comm]
      calc (j + 1) * (m + 1).choose (j + 1) * (4 ^ j * 4)
          = ((j + 1) * (m + 1).choose (j + 1)) * (4 ^ j * 4) := by ring
        _ = ((m + 1) * m.choose j) * (4 ^ j * 4) := by rw [h2]
        _ = (m + 1) * (4 * (m.choose j * 4 ^ j)) := by ring
    rw [Finset.sum_congr rfl key]
    rw [← Finset.mul_sum, ← Finset.mul_sum, hbin m]
    ring