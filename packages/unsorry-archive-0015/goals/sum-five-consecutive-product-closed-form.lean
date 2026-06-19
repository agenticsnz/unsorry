import Mathlib

theorem sum_five_consecutive_product_closed_form (n : ℕ) : 6 * ∑ k ∈ Finset.range (n + 1), k * (k + 1) * (k + 2) * (k + 3) * (k + 4) = n * (n + 1) * (n + 2) * (n + 3) * (n + 4) * (n + 5) := by
  sorry
