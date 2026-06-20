import Mathlib

open Finset
theorem sum_range_choose_mul_succ_choose_eq (n : ℕ) : ∑ k ∈ Finset.range (n + 1), n.choose k * (n + 1).choose k = (2 * n + 1).choose n := by
  have h : (2 * n + 1).choose n = ((n + 1) + n).choose n := by ring_nf
  rw [h, Nat.add_choose_eq, Finset.Nat.sum_antidiagonal_eq_sum_range_succ_mk]
  apply Finset.sum_congr rfl
  intro k hk
  rw [Nat.choose_symm (Finset.mem_range_succ_iff.mp hk)]
  ring
