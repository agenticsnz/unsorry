import Mathlib

theorem sum_range_fib_prod_shift_even_nat (n : ℕ) : ∑ i ∈ Finset.range (2 * n), Nat.fib i * Nat.fib (i + 1) = Nat.fib (2 * n) ^ 2 := by
  induction n with
  | zero => simp
  | succ k ih =>
    have h2 : 2 * (k + 1) = 2 * k + 1 + 1 := by ring
    rw [h2, Finset.sum_range_succ, Finset.sum_range_succ, ih]
    -- goal: fib(2k)^2 + fib(2k)*fib(2k+1) + fib(2k+1)*fib(2k+2) = fib(2k+2)^2
    have f1 : Nat.fib (2 * k + 1 + 1) = Nat.fib (2 * k) + Nat.fib (2 * k + 1) := by
      rw [Nat.fib_add_two]
    rw [f1]
    ring