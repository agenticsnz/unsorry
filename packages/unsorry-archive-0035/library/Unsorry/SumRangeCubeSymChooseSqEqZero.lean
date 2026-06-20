import Mathlib

theorem sum_range_cube_sym_choose_sq_eq_zero (n : ℕ) : ∑ k ∈ Finset.range (n + 1), ((n : ℤ) - 2 * k) ^ 3 * (n.choose k) ^ 2 = 0 := by
  have h := Finset.sum_range_reflect (fun k => ((n : ℤ) - 2 * k) ^ 3 * (n.choose k) ^ 2) (n + 1)
  set S := ∑ k ∈ Finset.range (n + 1), ((n : ℤ) - 2 * k) ^ 3 * (n.choose k) ^ 2 with hS
  -- h : ∑ j in range (n+1), f (n+1-1-j) = S
  have key : ∑ j ∈ Finset.range (n + 1), ((n : ℤ) - 2 * ↑(n + 1 - 1 - j)) ^ 3 * (n.choose (n + 1 - 1 - j)) ^ 2 = -S := by
    rw [hS, ← Finset.sum_neg_distrib]
    apply Finset.sum_congr rfl
    intro j hj
    simp only [Finset.mem_range, Nat.lt_succ_iff] at hj
    have hsub : n + 1 - 1 - j = n - j := by omega
    rw [hsub]
    have hnj : (n : ℤ) - 2 * ↑(n - j) = -((n : ℤ) - 2 * ↑j) := by
      rw [Nat.cast_sub hj]; ring
    rw [hnj, Nat.choose_symm hj]; ring
  rw [key] at h
  linarith