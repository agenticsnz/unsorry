import Mathlib

theorem sum_range_fib_two_mul_succ_eq_fib_pred (n : ℕ) : Finset.sum (Finset.range n) (fun i => Nat.fib (2 * i + 2)) = Nat.fib (2 * n + 1) - 1 := by
  sorry
