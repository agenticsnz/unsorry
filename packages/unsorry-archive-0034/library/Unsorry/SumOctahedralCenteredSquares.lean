import Mathlib

theorem sum_octahedral_centered_squares (n : ℕ) : 3 * ∑ k ∈ Finset.range n, (2 * (k + 1) ^ 2 - 2 * (k + 1) + 1) = n * (2 * n ^ 2 + 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    have h : 2 * (m + 1) ^ 2 - 2 * (m + 1) + 1 = 2 * m ^ 2 + 2 * m + 1 := by
      have : 2 * (m + 1) ^ 2 = (2 * (m + 1)) + (2 * m ^ 2 + 2 * m) := by ring
      omega
    rw [h]
    ring