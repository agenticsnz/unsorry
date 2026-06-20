import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Data.Finset.Interval
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic

open scoped BigOperators

theorem sum_icc_k_sq_add_one_mul_factorial_eq_prod (n : ℕ) :
    (∑ k ∈ Finset.Icc 1 n, (k ^ 2 + 1) * Nat.factorial k) =
      n * Nat.factorial (n + 1) := by
  induction n with
  | zero =>
      simp
  | succ n ih =>
      have hset : Finset.Icc 1 (n + 1) = insert (n + 1) (Finset.Icc 1 n) := by
        ext k
        simp only [Finset.mem_Icc, Finset.mem_insert]
        omega
      rw [hset, Finset.sum_insert]
      · rw [ih]
        rw [Nat.factorial_succ (n + 1)]
        ring_nf
      · simp [Finset.mem_Icc]
