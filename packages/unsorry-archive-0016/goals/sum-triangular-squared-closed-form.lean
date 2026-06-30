import Mathlib

theorem sum_triangular_squared_closed_form (n : ℕ) : 15 * ∑ k ∈ Finset.range (n + 1), k ^ 2 * (k + 1) ^ 2 = n * (n + 1) * (n + 2) * (3 * n ^ 2 + 6 * n + 1) := by
  sorry
