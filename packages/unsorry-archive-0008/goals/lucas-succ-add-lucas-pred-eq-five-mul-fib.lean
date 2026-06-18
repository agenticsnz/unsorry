import Mathlib

theorem lucas_succ_add_lucas_pred_eq_five_mul_fib (n : ℕ) :
    (Nat.fib (n + 2) + Nat.fib (n + 4)) + (Nat.fib n + Nat.fib (n + 2)) = 5 * Nat.fib (n + 2) := by
  sorry
