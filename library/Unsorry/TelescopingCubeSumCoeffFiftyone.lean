import Mathlib

/-- Goal `telescoping-cube-sum-coeff-fiftyone`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_cube_sum_coeff_fiftyone (n : ℕ) : ∑ k ∈ Finset.range n, (51 * (3 * (k : ℤ) ^ 2 + 3 * (k : ℤ) + 1)) = 51 * (n : ℤ) ^ 3 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
