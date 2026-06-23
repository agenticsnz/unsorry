import Mathlib

/-- Goal `telescoping-square-sum-coeff-fiftynine`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_square_sum_coeff_fiftynine (n : ℕ) : ∑ k ∈ Finset.range n, (2 * 59 * (k : ℤ) + 59) = 59 * (n : ℤ) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
