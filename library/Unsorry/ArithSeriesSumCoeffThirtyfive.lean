import Mathlib

/-- Goal `arith-series-sum-coeff-thirtyfive`: arithmetic-series closed form, by induction on `n`. -/
theorem arith_series_sum_coeff_thirtyfive (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 35) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 35 * (n : ℤ) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
