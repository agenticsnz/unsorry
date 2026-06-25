import Mathlib

/-- Goal `shift-square-sum-coeff-fortythree`: shifted-square-sum closed form, by induction on `n`. -/
theorem shift_square_sum_coeff_fortythree (n : ℕ) : 6 * ∑ k ∈ Finset.range n, ((k : ℤ) + 43) ^ 2 = (n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) + 6 * 43 * (n : ℤ) * ((n : ℤ) - 1) + 6 * (n : ℤ) * 43 ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
