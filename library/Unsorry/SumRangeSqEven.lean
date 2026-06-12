import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

theorem sum_range_sq_even (n : ℕ) :
    3 * ∑ i ∈ Finset.range n, (2 * i) ^ 2 = 2 * n * (n - 1) * (2 * n - 1) := by
  induction n with
  | zero => norm_num
  | succ k ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    have h1 : k + 1 - 1 = k := by omega
    have h2 : 2 * (k + 1) - 1 = 2 * k + 1 := by omega
    rw [h1, h2]
    cases k with
    | zero => norm_num
    | succ m =>
      have h3 : m + 1 - 1 = m := by omega
      have h4 : 2 * (m + 1) - 1 = 2 * m + 1 := by omega
      rw [h3, h4]
      ring
