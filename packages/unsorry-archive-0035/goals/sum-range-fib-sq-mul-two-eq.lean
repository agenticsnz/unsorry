import Mathlib

theorem sum_range_fib_sq_mul_two_eq (n : ℕ) : 2 * ∑ k ∈ Finset.range (n + 1), Nat.fib k ^ 2 = Nat.fib n * Nat.fib (n + 1) + Nat.fib (n + 1) * Nat.fib (n + 2) - Nat.fib (n + 1) ^ 2 := by
  sorry
