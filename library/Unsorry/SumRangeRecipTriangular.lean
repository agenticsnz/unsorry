import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

theorem sum_range_two_div_succ_mul_succ_succ (n : ℕ) :
    ∑ k ∈ Finset.range n, (2 : ℚ) / (((k : ℚ) + 1) * ((k : ℚ) + 2))
      = 2 * (n : ℚ) / ((n : ℚ) + 1) := by
  induction n with
  | zero => norm_num
  | succ k ih =>
    rw [Finset.sum_range_succ, ih]
    have _h1 : ((k : ℚ) + 1) ≠ 0 := by
      have hk : (k + 1 : ℕ) ≠ 0 := by omega
      exact_mod_cast hk
    have _h2 : ((k : ℚ) + 2) ≠ 0 := by
      have hk : (k + 2 : ℕ) ≠ 0 := by omega
      exact_mod_cast hk
    have _h3 : ((k : ℚ) + 1 + 1) ≠ 0 := by
      intro h
      exact _h2 (by linarith)
    push_cast
    field_simp
    ring
