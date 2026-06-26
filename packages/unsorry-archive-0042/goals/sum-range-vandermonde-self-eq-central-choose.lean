import Mathlib

theorem sum_range_vandermonde_self_eq_central_choose (n r : ℕ) (hr : r ≤ 2 * n) : ∑ k ∈ Finset.range (r + 1), n.choose k * n.choose (r - k) = (2 * n).choose r := by
  sorry
