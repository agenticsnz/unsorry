import Mathlib

theorem sum_octagonal_numbers_closed_form (n : ℕ) :
    2 * (∑ k ∈ Finset.range n, ((k : ℤ) + 1) * (3 * ((k : ℤ) + 1) - 2))
      = (n : ℤ) * ((n : ℤ) + 1) * (2 * (n : ℤ) - 1) := by
  sorry
