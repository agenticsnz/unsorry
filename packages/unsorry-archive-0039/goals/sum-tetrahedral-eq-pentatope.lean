import Mathlib

theorem sum_tetrahedral_eq_pentatope (n : ℕ) : 24 * ∑ k ∈ Finset.range (n + 1), k * (k + 1) * (k + 2) / 6 = n * (n + 1) * (n + 2) * (n + 3) := by
  sorry
