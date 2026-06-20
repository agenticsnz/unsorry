import Mathlib

open Finset in
theorem sum_range_two_k_sub_n_mul_choose_sq_eq_zero (n : ℕ) : ∑ k ∈ Finset.range (n + 1), (2 * (k : ℤ) - n) * (n.choose k : ℤ) ^ 2 = 0 := by
  have h := Finset.sum_range_reflect (fun k => (2 * (k : ℤ) - n) * (n.choose k : ℤ) ^ 2) (n + 1)
  simp only [Nat.add_sub_cancel] at h
  set S := ∑ k ∈ Finset.range (n + 1), (2 * (k : ℤ) - n) * (n.choose k : ℤ) ^ 2 with hS
  -- h : ∑ j in range (n+1), f (n - j) = S
  have key : ∑ j ∈ Finset.range (n + 1), (2 * ((n - j : ℕ) : ℤ) - n) * (n.choose (n - j) : ℤ) ^ 2
      = ∑ j ∈ Finset.range (n + 1), -((2 * (j : ℤ) - n) * (n.choose j : ℤ) ^ 2) := by
    apply Finset.sum_congr rfl
    intro j hj
    rw [Finset.mem_range, Nat.lt_succ_iff] at hj
    have h1 : ((n - j : ℕ) : ℤ) = (n : ℤ) - (j : ℤ) := by
      rw [Nat.cast_sub hj]
    rw [h1, Nat.choose_symm hj]
    ring
  rw [key, Finset.sum_neg_distrib] at h
  -- now h : -S = S
  linarith