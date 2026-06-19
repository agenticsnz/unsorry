import Mathlib

/-- Goal `lucas-succ-add-lucas-pred-eq-five-mul-fib`: `L(n+1)+L(n-1) = 5·F(n)`
written on `Nat.fib` via `L k = F(k-1)+F(k+1)`. Unfolding the Fibonacci
recurrence reduces it to linear arithmetic. See `library/index/`. -/
theorem lucas_succ_add_lucas_pred_eq_five_mul_fib (n : ℕ) :
    (Nat.fib (n + 2) + Nat.fib (n + 4)) + (Nat.fib n + Nat.fib (n + 2)) = 5 * Nat.fib (n + 2) := by
  have h2 : Nat.fib (n + 2) = Nat.fib n + Nat.fib (n + 1) := Nat.fib_add_two
  have h3 : Nat.fib (n + 3) = Nat.fib (n + 1) + Nat.fib (n + 2) := Nat.fib_add_two
  have h4 : Nat.fib (n + 4) = Nat.fib (n + 2) + Nat.fib (n + 3) := Nat.fib_add_two
  omega
