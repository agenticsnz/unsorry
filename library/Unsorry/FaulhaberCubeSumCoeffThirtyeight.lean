import Mathlib

/-- Goal `faulhaber-cube-sum-coeff-thirtyeight`: a Faulhaber power sum (degree 3, coefficient 38) closed form, by induction on `n`. -/
theorem faulhaber_cube_sum_coeff_thirtyeight (n : ℕ) : 152 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 3 = 38 * (((n : ℤ) * ((n : ℤ) - 1)) ^ 2) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
