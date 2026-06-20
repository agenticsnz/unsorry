import Mathlib

theorem sum_one_div_three_k_plus_one_mul_three_k_plus_four (n : ℕ) : (∑ k ∈ Finset.range n, (1 : ℚ) / ((3 * k + 1) * (3 * k + 4))) = n / (3 * n + 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    have h1 : (3 * (m : ℚ) + 1) ≠ 0 := by positivity
    have h2 : (3 * (m : ℚ) + 4) ≠ 0 := by positivity
    have h3 : (3 * ((m : ℚ) + 1) + 1) ≠ 0 := by positivity
    push_cast
    field_simp
    ring