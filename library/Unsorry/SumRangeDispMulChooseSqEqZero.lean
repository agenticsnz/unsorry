import Mathlib

theorem sum_range_disp_mul_choose_sq_eq_zero (n : ℕ) : ∑ k ∈ Finset.range (n + 1), ((n : ℤ) - 2 * k) * (n.choose k : ℤ) ^ 2 = 0 := by
  have h := Finset.sum_range_reflect (fun k => ((n : ℤ) - 2 * k) * (n.choose k : ℤ) ^ 2) (n + 1)
  -- h : ∑ j in range (n+1), f (n - j) = ∑ j in range (n+1), f j
  set S := ∑ k ∈ Finset.range (n + 1), ((n : ℤ) - 2 * k) * (n.choose k : ℤ) ^ 2 with hS
  have hrefl : ∑ j ∈ Finset.range (n + 1), ((n : ℤ) - 2 * ((n - j : ℕ) : ℤ)) * (n.choose (n - j) : ℤ) ^ 2 = S := h
  -- show the reflected summand equals -(original summand)
  have key : ∀ j ∈ Finset.range (n + 1),
      ((n : ℤ) - 2 * ((n - j : ℕ) : ℤ)) * (n.choose (n - j) : ℤ) ^ 2
        = - (((n : ℤ) - 2 * j) * (n.choose j : ℤ) ^ 2) := by
    intro j hj
    rw [Finset.mem_range, Nat.lt_succ_iff] at hj
    have hle : j ≤ n := hj
    have hcast : ((n - j : ℕ) : ℤ) = (n : ℤ) - (j : ℤ) := by
      rw [Nat.cast_sub hle]
    rw [hcast, Nat.choose_symm hle]
    ring
  rw [Finset.sum_congr rfl key, Finset.sum_neg_distrib] at hrefl
  -- hrefl : -S = S
  linarith [hrefl]