import Mathlib

theorem sum_range_lucas_shift_nat (n : ℕ) : ∑ i ∈ Finset.range n, (Nat.fib i + Nat.fib (i + 2)) = Nat.fib (n + 1) + Nat.fib (n + 3) - 3 := by
  sorry
