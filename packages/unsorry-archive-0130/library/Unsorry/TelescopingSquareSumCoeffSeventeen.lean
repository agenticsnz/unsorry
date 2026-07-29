import Mathlib

/-- Goal `telescoping-square-sum-coeff-seventeen`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_square_sum_coeff_seventeen (n : ℕ) : ∑ k ∈ Finset.range n, (2 * 17 * (k : ℤ) + 17) = 17 * (n : ℤ) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
