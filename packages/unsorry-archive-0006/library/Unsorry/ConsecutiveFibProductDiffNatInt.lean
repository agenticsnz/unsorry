import Mathlib

theorem consecutive_fib_product_diff_nat_int (n : ℕ) : (Nat.fib n : ℤ) * Nat.fib (n + 3) - Nat.fib (n + 1) * Nat.fib (n + 2) = (-1) ^ (n + 1) := by
  induction n with
  | zero => decide
  | succ k ih =>
    have r2 : (Nat.fib (k + 2) : ℤ) = Nat.fib k + Nat.fib (k + 1) := by
      exact_mod_cast Nat.fib_add_two
    have r4 : (Nat.fib (k + 1 + 3) : ℤ) = Nat.fib (k + 2) + Nat.fib (k + 3) := by
      have h : Nat.fib (k + 2 + 2) = Nat.fib (k + 2) + Nat.fib (k + 2 + 1) := Nat.fib_add_two
      have e : k + 1 + 3 = k + 2 + 2 := by ring
      rw [e]
      exact_mod_cast h
    have e1 : k + 1 + 1 = k + 2 := by ring
    have e2 : k + 1 + 2 = k + 3 := by ring
    rw [e1, e2, r4]
    have hpow : ((-1 : ℤ)) ^ (k + 1 + 1) = - (-1) ^ (k + 1) := by
      rw [pow_succ]; ring
    rw [hpow]
    linear_combination (-1 : ℤ) * ih - (Nat.fib (k + 3) : ℤ) * r2