import Mathlib

/-- Goal `telescoping-quintic-sum-coeff-fiftythree`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_quintic_sum_coeff_fiftythree (n : ℕ) : ∑ k ∈ Finset.range n, (53 * (5 * (k : ℤ) ^ 4 + 10 * (k : ℤ) ^ 3 + 10 * (k : ℤ) ^ 2 + 5 * (k : ℤ) + 1)) = 53 * (n : ℤ) ^ 5 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
