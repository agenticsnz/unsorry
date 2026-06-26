import Mathlib

/-- Goal `telescoping-square-sum-coeff-seventyseven`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_square_sum_coeff_seventyseven (n : ℕ) : ∑ k ∈ Finset.range n, (2 * 77 * (k : ℤ) + 77) = 77 * (n : ℤ) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
