import Mathlib

theorem alternating_sum_k_mul_choose_eq_zero (n : ℕ) (hn : 2 ≤ n) : ∑ k ∈ Finset.range (n + 1), (-1 : ℤ) ^ k * (k * n.choose k) = 0 := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  have hm : m ≠ 0 := by omega
  -- Peel the k = 0 term and reindex k ↦ k + 1.
  rw [Finset.sum_range_succ']
  simp only [Nat.cast_zero, mul_zero, mul_zero, zero_mul, add_zero, pow_zero]
  -- Now: ∑ k ∈ range (m+1), (-1)^(k+1) * ((k+1) * (m+1).choose (k+1)) = 0
  -- Use (m+1) * choose m k = choose (m+1) (k+1) * (k+1), i.e. (k+1) * choose (m+1) (k+1) = (m+1) * choose m k
  have key : ∀ k ∈ Finset.range (m + 1),
      (-1 : ℤ) ^ (k + 1) * ((↑(k + 1)) * ((m + 1).choose (k + 1) : ℤ))
        = (-(m + 1 : ℤ)) * ((-1) ^ k * (m.choose k : ℤ)) := by
    intro k _
    have h := Nat.add_one_mul_choose_eq m k
    -- h : (m + 1) * choose m k = choose (m + 1) (k + 1) * (k + 1)
    have hcast : ((↑(k + 1) : ℤ) * ((m + 1).choose (k + 1) : ℤ))
        = ((m + 1 : ℤ) * (m.choose k : ℤ)) := by
      have := congrArg (Nat.cast : ℕ → ℤ) h
      push_cast at this ⊢
      linarith [this]
    rw [hcast, pow_succ]
    ring
  rw [Finset.sum_congr rfl key, ← Finset.mul_sum]
  rw [Int.alternating_sum_range_choose_of_ne hm]
  ring