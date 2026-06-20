import Mathlib

open Nat Finset
theorem two_mul_sum_range_fib_triple_eq_fib_pred (n : ℕ) : 2 * Finset.sum (Finset.range n) (fun i => Nat.fib (3 * i)) = Nat.fib (3 * n - 1) - 1 := by
  sorry
