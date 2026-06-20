import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.Ring

open Finset

theorem sum_icc_id_mul_two_pow_pred (n : ℕ) :
    (∑ k ∈ Finset.Icc 1 n, (k : ℤ) * 2 ^ (k - 1)) = (n - 1) * 2 ^ n + 1 := by
  induction n with
  | zero =>
      simp
  | succ n ih =>
      cases n with
      | zero =>
          simp
      | succ m =>
          rw [Finset.sum_Icc_succ_top (by simp)]
          rw [ih]
          simp [pow_succ]
          ring
