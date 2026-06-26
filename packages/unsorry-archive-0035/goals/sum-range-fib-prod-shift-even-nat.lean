import Mathlib

theorem sum_range_fib_prod_shift_even_nat (n : ℕ) : ∑ i ∈ Finset.range (2 * n), Nat.fib i * Nat.fib (i + 1) = Nat.fib (2 * n) ^ 2 := by
  sorry
