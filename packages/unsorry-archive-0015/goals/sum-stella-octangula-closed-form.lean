import Mathlib

theorem sum_stella_octangula_closed_form (n : ℕ) :
    2 * ∑ k ∈ Finset.range n, ((k + 1 : ℤ) * (2 * (k + 1) ^ 2 - 1)) =
      (n : ℤ) * (n + 1) * (n ^ 2 + n - 1) := by
  sorry
