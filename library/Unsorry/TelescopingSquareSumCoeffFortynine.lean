import Mathlib

/-- Goal `telescoping-square-sum-coeff-fortynine`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_square_sum_coeff_fortynine (n : ℕ) : ∑ k ∈ Finset.range n, (2 * 49 * (k : ℤ) + 49) = 49 * (n : ℤ) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
