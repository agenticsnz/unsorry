import Mathlib

open Finset in
theorem sum_range_choose_mul_succ_choose_succ_eq_central_shift (n : ℕ) : ∑ k ∈ Finset.range (n + 1), n.choose k * (n + 1).choose (k + 1) = (2 * n + 1).choose (n + 1) := by
  have hv : (2 * n + 1).choose (n + 1)
      = ∑ k ∈ Finset.range (n + 1), n.choose k * (n + 1).choose (n + 1 - k) := by
    have he : (2 * n + 1) = n + (n + 1) := by ring
    rw [he, Nat.add_choose_eq, Finset.Nat.sum_antidiagonal_eq_sum_range_succ_mk,
      Finset.sum_range_succ, Nat.choose_eq_zero_of_lt (by omega : n < n + 1), zero_mul, add_zero]
  rw [hv, ← Finset.sum_range_reflect]
  apply Finset.sum_congr rfl
  intro k hk
  rw [Finset.mem_range] at hk
  have he1 : n + 1 - 1 - k = n - k := by omega
  rw [he1, Nat.choose_symm (by omega : k ≤ n)]
  have he2 : n - k + 1 = n + 1 - k := by omega
  rw [he2]