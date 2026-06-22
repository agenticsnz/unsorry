import Mathlib

theorem sum_range_k_mul_factorial_eq_factorial_succ_sub_one (n : ℕ) : ∑ k ∈ Finset.range (n + 1), k * Nat.factorial k = Nat.factorial (n + 1) - 1 := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    have h : 1 ≤ Nat.factorial (m + 1) := Nat.one_le_iff_ne_zero.mpr (Nat.factorial_ne_zero _)
    have hfac : Nat.factorial (m + 1 + 1) = (m + 1 + 1) * Nat.factorial (m + 1) :=
      Nat.factorial_succ (m + 1)
    have key : (m + 1) * Nat.factorial (m + 1) + (Nat.factorial (m + 1) - 1)
        = Nat.factorial (m + 1 + 1) - 1 := by
      rw [hfac]
      have : (m + 1 + 1) * Nat.factorial (m + 1)
          = (m + 1) * Nat.factorial (m + 1) + Nat.factorial (m + 1) := by ring
      omega
    omega