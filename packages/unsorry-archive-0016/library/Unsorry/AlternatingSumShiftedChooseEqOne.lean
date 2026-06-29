import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Tactic.Ring

open scoped BigOperators

theorem alternating_sum_shifted_choose_eq_one (n : ℕ) : ∑ k ∈ Finset.range (n + 1), (-1 : ℤ) ^ k * (n + 1).choose (k + 1) = 1 := by
  have hfull :
      (∑ k ∈ Finset.range (n + 2), (-1 : ℤ) ^ k * ((n + 1).choose k : ℤ)) = 0 := by
    calc
      (∑ k ∈ Finset.range (n + 2), (-1 : ℤ) ^ k * ((n + 1).choose k : ℤ))
          = ((-1 : ℤ) + 1) ^ (n + 1) := by
            simpa [mul_assoc, mul_left_comm, mul_comm] using
              (add_pow (-1 : ℤ) 1 (n + 1)).symm
      _ = 0 := by
            rw [neg_add_cancel]
            exact zero_pow (Nat.succ_ne_zero n)
  have htail :
      (∑ k ∈ Finset.range (n + 1), (-1 : ℤ) ^ (k + 1) * ((n + 1).choose (k + 1) : ℤ)) = -1 := by
    have h := hfull
    rw [Finset.sum_range_succ'] at h
    simp at h
    have h' := congrArg (fun z : ℤ => z - 1) h
    simpa [add_assoc, add_comm, add_left_comm] using h'
  have hneg :
      (∑ k ∈ Finset.range (n + 1), (-1 : ℤ) ^ k * ((n + 1).choose (k + 1) : ℤ)) =
        -∑ k ∈ Finset.range (n + 1), (-1 : ℤ) ^ (k + 1) * ((n + 1).choose (k + 1) : ℤ) := by
    rw [← Finset.sum_neg_distrib]
    apply Finset.sum_congr rfl
    intro k _
    rw [pow_succ]
    ring
  rw [hneg, htail]
  ring
