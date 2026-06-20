import Mathlib

theorem sum_octagonal_running_closed_form (n : ℕ) : 2 * ∑ k ∈ Finset.range (n + 1), k * (3 * k - 2) = n * (n + 1) * (2 * n - 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    cases m with
    | zero => decide
    | succ p =>
      have e1 : 2 * (p + 1) - 1 = 2 * p + 1 := by omega
      have e2 : 2 * (p + 1 + 1) - 1 = 2 * p + 3 := by omega
      have e3 : 3 * (p + 1 + 1) - 2 = 3 * p + 4 := by omega
      rw [e1, e2, e3]
      ring