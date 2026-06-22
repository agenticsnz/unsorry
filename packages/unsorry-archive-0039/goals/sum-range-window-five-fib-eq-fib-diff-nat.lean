import Mathlib

theorem sum_range_window_five_fib_eq_fib_diff_nat (n : ℕ) : Finset.sum (Finset.range 5) (fun j => Nat.fib (n + j)) = Nat.fib (n + 6) - Nat.fib (n + 1) := by
  sorry
