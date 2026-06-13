import Mathlib

theorem sum_range_fib_two_mul (n : ℕ) :
    ∑ i ∈ Finset.range n, Nat.fib (2 * (i + 1)) = Nat.fib (2 * n + 1) - 1 := by
  sorry
