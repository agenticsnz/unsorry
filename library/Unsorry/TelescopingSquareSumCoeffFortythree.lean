import Mathlib

/-- Goal `telescoping-square-sum-coeff-fortythree`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_square_sum_coeff_fortythree (n : ℕ) : ∑ k ∈ Finset.range n, (2 * 43 * (k : ℤ) + 43) = 43 * (n : ℤ) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
