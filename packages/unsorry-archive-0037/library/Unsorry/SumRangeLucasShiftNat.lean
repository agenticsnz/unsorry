import Mathlib

theorem sum_range_lucas_shift_nat (n : ℕ) : ∑ i ∈ Finset.range n, (Nat.fib i + Nat.fib (i + 2)) = Nat.fib (n + 1) + Nat.fib (n + 3) - 3 := by
  have key : ∀ m : ℕ, (∑ i ∈ Finset.range m, (Nat.fib i + Nat.fib (i + 2))) + 3 = Nat.fib (m + 1) + Nat.fib (m + 3) := by
    intro m
    induction m with
    | zero => decide
    | succ k ih =>
      rw [Finset.sum_range_succ, show k + 1 + 1 = k + 2 by ring,
        show k + 1 + 3 = k + 4 by ring]
      have e2 : Nat.fib (k + 4) = Nat.fib (k + 2) + Nat.fib (k + 3) := by
        rw [show k + 4 = (k + 2) + 2 by ring, Nat.fib_add_two]
      have e3 : Nat.fib (k + 2) = Nat.fib k + Nat.fib (k + 1) := by
        rw [Nat.fib_add_two]
      omega
  have hk := key n
  omega