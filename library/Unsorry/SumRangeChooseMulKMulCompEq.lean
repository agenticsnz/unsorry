import Mathlib
open Nat Finset

theorem sum_range_choose_mul_k_mul_comp_eq (n : ℕ) : 4 * ∑ k ∈ Finset.range (n + 1), n.choose k * (k * (n - k)) = n * (n - 1) * 2 ^ n := by
  match n with
  | 0 => simp
  | 1 => decide
  | (m + 2) =>
    -- term identity for the shifted index
    have term : ∀ j, (m+2).choose (j+1) * ((j+1) * ((m+2) - (j+1))) = (m+2)*(m+1)* m.choose j := by
      intro j
      have h1 : (m+2).choose (j+1) * (j+1) = (m+2) * (m+1).choose j := by
        have h := Nat.add_one_mul_choose_eq (m+1) j
        -- ((m+1)+1) * choose (m+1) j = choose (m+2) (j+1) * (j+1)
        have e : (m + 1) + 1 = m + 2 := by omega
        rw [e] at h
        exact h.symm
      have h2 : (m+1).choose j * ((m+2) - (j+1)) = (m+1) * m.choose j := by
        have := Nat.choose_mul_succ_eq m j  -- choose m j * (m+1) = choose (m+1) j * (m+1 - j)
        have hsub : (m+2) - (j+1) = (m+1) - j := by omega
        rw [hsub, ← this, Nat.mul_comm]
      calc (m+2).choose (j+1) * ((j+1) * ((m+2) - (j+1)))
          = ((m+2).choose (j+1) * (j+1)) * ((m+2) - (j+1)) := by ring
        _ = ((m+2) * (m+1).choose j) * ((m+2) - (j+1)) := by rw [h1]
        _ = (m+2) * ((m+1).choose j * ((m+2) - (j+1))) := by ring
        _ = (m+2) * ((m+1) * m.choose j) := by rw [h2]
        _ = (m+2)*(m+1)* m.choose j := by ring
    -- peel off k=0 and reindex
    rw [Finset.sum_range_succ']
    simp only [Nat.choose_zero_right, Nat.zero_mul, Nat.mul_zero, Nat.add_zero]
    -- now sum over j in range (m+2) of choose (m+2) (j+1) * ((j+1) * (m+2-(j+1)))
    have : ∑ j ∈ Finset.range (m+2), (m+2).choose (j+1) * ((j+1) * ((m+2) - (j+1)))
         = ∑ j ∈ Finset.range (m+2), (m+2)*(m+1)* m.choose j := by
      apply Finset.sum_congr rfl
      intro j _
      exact term j
    rw [this, ← Finset.mul_sum]
    -- sum over j in range (m+2) of choose m j = sum over range (m+1) = 2^m
    have hs : ∑ j ∈ Finset.range (m+2), m.choose j = 2 ^ m := by
      rw [Finset.sum_range_succ]
      rw [Nat.choose_eq_zero_of_lt (by omega), Nat.add_zero]
      exact Nat.sum_range_choose m
    rw [hs]
    -- goal: 4 * ((m+2)*(m+1)*2^m) = (m+2)*((m+2)-1)*2^(m+2)
    have : (m+2) - 1 = m + 1 := by omega
    rw [this]
    ring