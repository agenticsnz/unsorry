import Mathlib

theorem sum_range_recip_odd_pair_step_two_eq_n_div (n : ℕ) : ∑ k ∈ Finset.range n, (1 : ℝ) / ((2 * k + 1) * (2 * k + 3)) = n / (2 * n + 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    have h1 : (2 * (m : ℝ) + 1) ≠ 0 := by positivity
    have h2 : (2 * (m : ℝ) + 3) ≠ 0 := by positivity
    have h3 : (2 * ((m : ℝ) + 1) + 1) ≠ 0 := by positivity
    push_cast
    field_simp
    ring