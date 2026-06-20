import Mathlib

theorem cassini_nat_fib_int (n : ℕ) : (Nat.fib n : ℤ) * Nat.fib (n + 2) - Nat.fib (n + 1) ^ 2 = (-1) ^ (n + 1) := by
  induction n with
  | zero => simp
  | succ k ih =>
    have e2 : (Nat.fib (k + 2) : ℤ) = Nat.fib k + Nat.fib (k + 1) := by
      exact_mod_cast Nat.fib_add_two
    have e3 : (Nat.fib (k + 1 + 2) : ℤ) = Nat.fib (k + 1) + Nat.fib (k + 2) := by
      have : Nat.fib (k + 1 + 2) = Nat.fib (k + 1) + Nat.fib (k + 2) := by
        rw [Nat.fib_add_two]
      exact_mod_cast this
    have hg : (Nat.fib (k + 1) : ℤ) = Nat.fib (k + 1) := rfl
    rw [show k + 1 + 1 = k + 2 from rfl, e3, e2]
    rw [show k + 1 + 1 = k + 2 from rfl, e2] at ih
    have pow : ((-1 : ℤ)) ^ (k + 1 + 1) = - (-1) ^ (k + 1) := by ring
    rw [show k + 1 + 1 = k + 2 from rfl] at pow
    rw [pow]
    linear_combination -ih