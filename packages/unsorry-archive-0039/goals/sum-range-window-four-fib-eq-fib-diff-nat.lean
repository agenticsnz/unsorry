import Mathlib

theorem sum_range_window_four_fib_eq_fib_diff_nat (n : ℕ) : Finset.sum (Finset.range 4) (fun j => Nat.fib (n + j)) = Nat.fib (n + 5) - Nat.fib (n + 1) := by
  sorry
