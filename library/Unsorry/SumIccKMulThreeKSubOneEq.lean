import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.Ring.RingNF

open scoped BigOperators

theorem sum_icc_k_mul_three_k_sub_one_eq (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n, k * (3 * k - 1) = n ^ 2 * (n + 1) := by
  induction n with
  | zero =>
      simp
  | succ n ih =>
      change
        ∑ k ∈ Finset.Icc 1 (n + 1), k * (3 * k - 1) =
          (n + 1) ^ 2 * (n + 2)
      rw [Finset.sum_Icc_succ_top]
      · rw [ih]
        have hterm : 3 * (n + 1) - 1 = 3 * n + 2 := by
          calc
            3 * (n + 1) - 1 = (3 * n + 3) - 1 := by
              rw [Nat.mul_add, Nat.mul_one]
            _ = 3 * n + (3 - 1) := by
              rw [Nat.add_sub_assoc (by decide : 1 ≤ 3)]
            _ = 3 * n + 2 := rfl
        rw [hterm]
        ring_nf
      · exact Nat.succ_pos n
