import Mathlib.Data.Nat.Fib.Basic

private lemma fib_int_add_two (n : ℕ) :
    (Nat.fib (n + 2) : ℤ) = (Nat.fib n : ℤ) + Nat.fib (n + 1) := by
  rw [Nat.fib_add_two]
  exact Nat.cast_add _ _

private lemma catalan_r2_shift_step (n : ℕ) :
    (Nat.fib (n + 3) : ℤ) ^ 2 - Nat.fib (n + 1) * Nat.fib (n + 5) =
      -((Nat.fib (n + 2) : ℤ) ^ 2 - Nat.fib n * Nat.fib (n + 4)) := by
  have h2 : (Nat.fib (n + 2) : ℤ) = Nat.fib n + Nat.fib (n + 1) :=
    fib_int_add_two n
  have h3 : (Nat.fib (n + 3) : ℤ) = Nat.fib (n + 1) + Nat.fib (n + 2) :=
    fib_int_add_two (n + 1)
  have h4 : (Nat.fib (n + 4) : ℤ) = Nat.fib (n + 2) + Nat.fib (n + 3) :=
    fib_int_add_two (n + 2)
  have h5 : (Nat.fib (n + 5) : ℤ) = Nat.fib (n + 3) + Nat.fib (n + 4) :=
    fib_int_add_two (n + 3)
  rw [h5, h4, h3, h2]
  ring

theorem catalan_r2_shift_nat_fib_int (n : ℕ) :
    (Nat.fib (n + 2) : ℤ) ^ 2 - Nat.fib n * Nat.fib (n + 4) = (-1) ^ n := by
  induction n with
  | zero =>
      simp
  | succ n ih =>
      calc
        (Nat.fib (Nat.succ n + 2) : ℤ) ^ 2 -
            Nat.fib (Nat.succ n) * Nat.fib (Nat.succ n + 4) =
            -((Nat.fib (n + 2) : ℤ) ^ 2 - Nat.fib n * Nat.fib (n + 4)) := by
          exact catalan_r2_shift_step n
        _ = -((-1 : ℤ) ^ n) := by
          rw [ih]
        _ = (-1 : ℤ) ^ Nat.succ n := by
          rw [pow_succ]
          ring
