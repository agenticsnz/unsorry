import Mathlib

/-- Goal `telescoping-cube-sum-coeff-fortyfour`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_cube_sum_coeff_fortyfour (n : ℕ) : ∑ k ∈ Finset.range n, (44 * (3 * (k : ℤ) ^ 2 + 3 * (k : ℤ) + 1)) = 44 * (n : ℤ) ^ 3 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
