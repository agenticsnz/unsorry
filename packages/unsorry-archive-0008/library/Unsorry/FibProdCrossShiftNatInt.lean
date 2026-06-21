import Mathlib

theorem fib_prod_cross_shift_nat_int (n : ℕ) : (Nat.fib (n + 1) : ℤ) * Nat.fib (n + 2) - Nat.fib n * Nat.fib (n + 3) = (-1) ^ n := by
  induction n with
  | zero => simp
  | succ k ih =>
    -- index arithmetic (definitional)
    have e1 : Nat.fib (k + 1 + 1) = Nat.fib (k + 2) := rfl
    have e2 : Nat.fib (k + 1 + 2) = Nat.fib (k + 3) := rfl
    have e3 : Nat.fib (k + 1 + 3) = Nat.fib (k + 4) := rfl
    -- recurrences
    have e4 : Nat.fib (k + 4) = Nat.fib (k + 3) + Nat.fib (k + 2) := by
      have := Nat.fib_add_two (n := k + 2)
      simp only [show k + 2 + 2 = k + 4 from rfl, show k + 2 + 1 = k + 3 from rfl] at this
      rw [this]; ring
    have e5 : Nat.fib (k + 3) = Nat.fib (k + 2) + Nat.fib (k + 1) := by
      have := Nat.fib_add_two (n := k + 1)
      simp only [show k + 1 + 2 = k + 3 from rfl, show k + 1 + 1 = k + 2 from rfl] at this
      rw [this]; ring
    have e6 : Nat.fib (k + 2) = Nat.fib (k + 1) + Nat.fib k := by
      have := Nat.fib_add_two (n := k)
      rw [this]; ring
    rw [e1, e2, e3]
    rw [pow_succ]
    push_cast [e4, e5, e6] at ih ⊢
    nlinarith [ih]