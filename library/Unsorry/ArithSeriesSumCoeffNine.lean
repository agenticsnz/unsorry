import Mathlib

/-- Goal `arith-series-sum-coeff-nine`: arithmetic-series closed form, by induction on `n`. -/
theorem arith_series_sum_coeff_nine (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 9) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 9 * (n : ℤ) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
