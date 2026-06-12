import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

theorem sum_range_mul_two_pow (n : ℕ) :
    ∑ i ∈ Finset.range n, (i : ℤ) * 2 ^ i = (n - 2) * 2 ^ n + 2 := by
  induction n with
  | zero => norm_num
  | succ k ih =>
    rw [Finset.sum_range_succ, ih]
    push_cast
    ring
