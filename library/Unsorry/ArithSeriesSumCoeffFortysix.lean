import Mathlib

/-- Goal `arith-series-sum-coeff-fortysix`: arithmetic-series closed form, by induction on `n`. -/
theorem arith_series_sum_coeff_fortysix (n : ℕ) : 2 * ∑ k ∈ Finset.range n, ((k : ℤ) + 46) = (n : ℤ) * ((n : ℤ) - 1) + 2 * 46 * (n : ℤ) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
