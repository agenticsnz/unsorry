import Mathlib

theorem sum_range_succ_mul_choose_sq_eq (n : ℕ) : 2 * ∑ k ∈ Finset.range (n + 1), (k + 1) * n.choose k ^ 2 = (n + 2) * (2 * n).choose n := by
  -- The reflected sum equals the original sum
  have hreflect : (∑ k ∈ Finset.range (n + 1), (n - k + 1) * n.choose k ^ 2)
      = ∑ k ∈ Finset.range (n + 1), (k + 1) * n.choose k ^ 2 := by
    have h := Finset.sum_range_reflect (fun k => (k + 1) * n.choose k ^ 2) (n + 1)
    simp only [Nat.add_sub_cancel] at h
    -- h : ∑ j, (n - j + 1) * n.choose (n - j) ^ 2 = ∑ j, (j + 1) * n.choose j ^ 2
    rw [← h]
    apply Finset.sum_congr rfl
    intro j hj
    rw [Finset.mem_range, Nat.lt_succ_iff] at hj
    rw [Nat.choose_symm hj]
  -- 2 * S = S + reflected S = sum of (n+2) * choose^2
  have key : 2 * ∑ k ∈ Finset.range (n + 1), (k + 1) * n.choose k ^ 2
      = ∑ k ∈ Finset.range (n + 1), (n + 2) * n.choose k ^ 2 := by
    rw [two_mul]
    nth_rewrite 1 [← hreflect]
    rw [← Finset.sum_add_distrib]
    apply Finset.sum_congr rfl
    intro j hj
    rw [Finset.mem_range, Nat.lt_succ_iff] at hj
    have : (n - j + 1) + (j + 1) = n + 2 := by omega
    rw [← add_mul, this]
  rw [key, ← Finset.mul_sum, Nat.sum_range_choose_sq]