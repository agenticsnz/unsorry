import Mathlib

theorem sum_vandermonde_diagonal_eq_choose (n m : ℕ) : ∑ k ∈ Finset.range (n + 1), n.choose k * m.choose k = (n + m).choose n := by
  sorry
