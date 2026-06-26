import Mathlib

theorem sum_range_window_five_fib_eq_fib_diff_nat (n : ℕ) : Finset.sum (Finset.range 5) (fun j => Nat.fib (n + j)) = Nat.fib (n + 6) - Nat.fib (n + 1) := by
  simp only [Finset.sum_range_succ, Finset.sum_range_zero, Nat.add_zero]
  have h6 : Nat.fib (n + 6) = Nat.fib (n + 5) + Nat.fib (n + 4) := by
    rw [show n + 6 = (n + 4) + 2 from by ring, Nat.fib_add_two]; ring_nf
  have h5 : Nat.fib (n + 5) = Nat.fib (n + 4) + Nat.fib (n + 3) := by
    rw [show n + 5 = (n + 3) + 2 from by ring, Nat.fib_add_two]; ring_nf
  have h4 : Nat.fib (n + 4) = Nat.fib (n + 3) + Nat.fib (n + 2) := by
    rw [show n + 4 = (n + 2) + 2 from by ring, Nat.fib_add_two]; ring_nf
  have h3 : Nat.fib (n + 3) = Nat.fib (n + 2) + Nat.fib (n + 1) := by
    rw [show n + 3 = (n + 1) + 2 from by ring, Nat.fib_add_two]; ring_nf
  have h2 : Nat.fib (n + 2) = Nat.fib n + Nat.fib (n + 1) := Nat.fib_add_two
  omega