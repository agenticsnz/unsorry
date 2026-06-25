import Mathlib

/-- Goal `telescoping-cube-sum-coeff-seventeen`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_cube_sum_coeff_seventeen (n : ℕ) : ∑ k ∈ Finset.range n, (17 * (3 * (k : ℤ) ^ 2 + 3 * (k : ℤ) + 1)) = 17 * (n : ℤ) ^ 3 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
