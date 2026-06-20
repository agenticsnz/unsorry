import Mathlib

theorem sum_range_fib_sq_mul_two_eq (n : ℕ) : 2 * ∑ k ∈ Finset.range (n + 1), Nat.fib k ^ 2 = Nat.fib n * Nat.fib (n + 1) + Nat.fib (n + 1) * Nat.fib (n + 2) - Nat.fib (n + 1) ^ 2 := by
  have key : ∑ k ∈ Finset.range (n + 1), Nat.fib k ^ 2 = Nat.fib n * Nat.fib (n + 1) := by
    induction n with
    | zero => simp
    | succ m ih =>
      rw [Finset.sum_range_succ, ih]
      have : Nat.fib (m + 2) = Nat.fib (m + 1) + Nat.fib m := by
        rw [Nat.fib_add_two]; ring
      rw [this]
      ring
  rw [key]
  have h2 : Nat.fib (n + 2) = Nat.fib (n + 1) + Nat.fib n := by
    rw [Nat.fib_add_two]; ring
  rw [h2]
  ring_nf
  omega