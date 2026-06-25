import Mathlib

/-- Goal `faulhaber-quartic-sum-coeff-fiftyfour`: a Faulhaber power sum (degree 4, coefficient 54) closed form, by induction on `n`. -/
theorem faulhaber_quartic_sum_coeff_fiftyfour (n : ℕ) : 1620 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 4 = 54 * ((n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) * (3 * (n : ℤ) ^ 2 - 3 * (n : ℤ) - 1)) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
