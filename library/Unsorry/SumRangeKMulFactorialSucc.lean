import Mathlib

theorem sum_range_k_mul_factorial_succ (n : ℕ) : (∑ k ∈ Finset.range n, k * k.factorial) + 1 = n.factorial := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_range_succ]
    rw [Nat.factorial_succ]
    rw [add_right_comm, ih]
    ring