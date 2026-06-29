import Mathlib

theorem sum_range_window_four_fib_eq_fib_diff_nat (n : ℕ) : Finset.sum (Finset.range 4) (fun j => Nat.fib (n + j)) = Nat.fib (n + 5) - Nat.fib (n + 1) := by
  simp only [Finset.sum_range_succ, Finset.sum_range_zero]
  have h5 : Nat.fib (n + 5) = Nat.fib (n + 4) + Nat.fib (n + 3) := by
    rw [show n + 5 = (n + 3) + 2 by ring, Nat.fib_add_two]; ring_nf
  have h4 : Nat.fib (n + 4) = Nat.fib (n + 3) + Nat.fib (n + 2) := by
    rw [show n + 4 = (n + 2) + 2 by ring, Nat.fib_add_two]; ring_nf
  have h3 : Nat.fib (n + 3) = Nat.fib (n + 2) + Nat.fib (n + 1) := by
    rw [show n + 3 = (n + 1) + 2 by ring, Nat.fib_add_two]; ring_nf
  have h2 : Nat.fib (n + 2) = Nat.fib (n + 1) + Nat.fib n := by
    rw [show n + 2 = n + 2 by ring, Nat.fib_add_two]; ring_nf
  simp only [Nat.add_zero]
  omega