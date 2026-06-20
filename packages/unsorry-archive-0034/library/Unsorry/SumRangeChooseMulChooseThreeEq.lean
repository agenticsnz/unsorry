import Mathlib

open Nat Finset
theorem sum_range_choose_mul_choose_three_eq (n : ℕ) : 8 * ∑ k ∈ Finset.range (n + 1), n.choose k * k.choose 3 = n.choose 3 * 2 ^ n := by
  rcases Nat.lt_or_ge n 3 with hn | hn
  · interval_cases n <;> decide
  · obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le hn  -- n = 3 + m
    have key : ∑ k ∈ Finset.range (3 + m + 1), (3 + m).choose k * k.choose 3
        = (3 + m).choose 3 * ∑ j ∈ Finset.range (m + 1), m.choose j := by
      rw [Finset.range_eq_Ico,
        ← Finset.sum_Ico_consecutive _ (by omega : (0:ℕ) ≤ 3) (by omega : (3:ℕ) ≤ 3 + m + 1)]
      have hlow : ∑ k ∈ Finset.Ico 0 3, (3 + m).choose k * k.choose 3 = 0 := by
        rw [← Finset.range_eq_Ico]
        rw [Finset.sum_range_succ, Finset.sum_range_succ, Finset.sum_range_succ,
          Finset.sum_range_zero]
        rw [show Nat.choose 0 3 = 0 from rfl, show Nat.choose 1 3 = 0 from rfl,
          show Nat.choose 2 3 = 0 from rfl]
        ring
      rw [hlow, zero_add, Finset.sum_Ico_eq_sum_range]
      have hrange : 3 + m + 1 - 3 = m + 1 := by omega
      rw [hrange, Finset.mul_sum]
      apply Finset.sum_congr rfl
      intro j hj
      have h3 : (3 : ℕ) ≤ 3 + j := by omega
      rw [Nat.choose_mul h3, Nat.add_sub_cancel_left, Nat.add_sub_cancel_left]
    rw [key, Nat.sum_range_choose, pow_add]
    ring