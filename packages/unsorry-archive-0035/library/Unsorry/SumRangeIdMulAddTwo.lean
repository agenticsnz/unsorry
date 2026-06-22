import Mathlib

theorem sum_range_id_mul_add_two (n : ℕ) : 6 * (∑ i ∈ Finset.range n, i * (i + 2)) = n * (n - 1) * (2 * n + 5) := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    simp only [Nat.add_sub_cancel]
    cases k with
    | zero => simp
    | succ m =>
      simp only [Nat.add_sub_cancel]
      ring