import Mathlib

theorem sum_range_succ_mul_factorial_succ (n : ℕ) : (∑ i ∈ Finset.range n, (i + 1) * (i + 1).factorial) + 1 = (n + 1).factorial := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_range_succ]
    have h : (∑ i ∈ Finset.range k, (i + 1) * (i + 1).factorial) + (k + 1) * (k + 1).factorial + 1
        = ((∑ i ∈ Finset.range k, (i + 1) * (i + 1).factorial) + 1) + (k + 1) * (k + 1).factorial := by
      ring
    rw [h, ih]
    rw [show k + 1 + 1 = (k + 1) + 1 from rfl, Nat.factorial_succ (k + 1)]
    ring