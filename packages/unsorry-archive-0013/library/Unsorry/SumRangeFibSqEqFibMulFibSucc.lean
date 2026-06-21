import Mathlib

set_option linter.unusedTactic false in
set_option linter.unreachableTactic false in
set_option linter.unusedVariables false in
theorem sum_range_fib_sq_eq_fib_mul_fib_succ (n : ℕ) : Finset.sum (Finset.range n) (fun i => Nat.fib (i + 1) ^ 2) = Nat.fib n * Nat.fib (n + 1) := by
  first
    | (
      first
      | (simp only [Finset.sum_range_succ, Finset.sum_range_zero, Nat.fib_add_two]; ring)
      | (simp only [Finset.sum_range_succ, Finset.sum_range_zero, Nat.fib_add_two]; omega)
      | (simp [Finset.sum_range_succ, Nat.fib_add_two]; omega)
      | (simp [Finset.sum_range_succ, Nat.fib_add_two]; ring)
      | (simp [Nat.fib_add_two, Nat.gcd_add_self_right, Nat.gcd_add_self_left]; done)
      | (rw [Nat.fib_add_two]; simp [Nat.gcd_add_self_right, Nat.gcd_add_self_left]; done)
    )
    | (
      induction n with
    | zero => first | rfl | simp | norm_num | decide | (simp [Finset.sum_range_zero, Nat.fib]) | (norm_num [Nat.fib])
    | succ n ih =>
      first
        | (rw [Finset.sum_range_succ, ih, Nat.fib_add_two]; ring)
        | (rw [Finset.sum_range_succ, ih, Nat.fib_add_two]; omega)
        | (rw [Finset.sum_range_succ, ih]; simp [Nat.fib_add_two]; ring)
        | (rw [Finset.sum_range_succ, ih]; simp [Nat.fib_add_two]; omega)
        | (simp only [Finset.sum_range_succ, ih, Nat.fib_add_two]; ring)
        | (simp [Finset.sum_range_succ, Nat.fib_add_two] at *; omega)
        | (rw [Finset.sum_range_succ, ih]; omega)
        | (rw [Finset.sum_range_succ, ih]; ring)
        | (push_cast [Finset.sum_range_succ, Nat.fib_add_two] at *; linear_combination ih)
        | (push_cast [Finset.sum_range_succ, Nat.fib_add_two] at *; linear_combination -ih)
        | (simp only [Nat.fib_add_two, pow_succ]; push_cast; linear_combination -ih)
        | (simp only [Nat.fib_add_two, pow_succ]; push_cast; linear_combination ih)
        | (simp only [Nat.fib_add_two, pow_succ]; push_cast; ring_nf; linear_combination -ih)
        | (rw [Nat.fib_add_two]; push_cast [pow_succ]; ring)
        | (simp [Nat.fib_add_two]; ring)
        | (simp [Nat.fib_add_two]; omega)
        | (simp [Nat.fib_add_two] at *; ring_nf; omega)
    )
