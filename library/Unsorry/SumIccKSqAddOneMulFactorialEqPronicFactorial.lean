import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.Ring

open scoped BigOperators

theorem sum_icc_k_sq_add_one_mul_factorial_eq_pronic_factorial (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n, (k^2 + 1) * k.factorial = n * (n+1).factorial := by
  induction n with
  | zero =>
      simp
  | succ n ih =>
      rw [Finset.sum_Icc_succ_top (Nat.succ_le_succ (Nat.zero_le n))]
      rw [ih]
      rw [Nat.factorial_succ (n + 1)]
      ring
