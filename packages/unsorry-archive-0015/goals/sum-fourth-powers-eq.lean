import Mathlib

theorem sum_fourth_powers_eq (n : ℕ) : 30 * ∑ k ∈ Finset.range n, ((k : ℤ) ^ 4) = (n - 1) * n * (2 * n - 1) * (3 * (n - 1) ^ 2 + 3 * (n - 1) - 1) := by
  sorry
