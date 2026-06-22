import Mathlib

theorem sum_decagonal_numbers_closed_form (n : ℕ) :
    6 * ∑ k ∈ Finset.Icc 1 n, ((k : ℤ) * (4 * k - 3)) = n * (n + 1) * (8 * n - 5) := by
  sorry
