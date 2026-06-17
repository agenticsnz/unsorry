import Mathlib

theorem sum_rhombic_dodecahedral_eq_fourth_power (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n, ((2 * (k : ℤ) - 1) * (2 * (k : ℤ)^2 - 2 * (k : ℤ) + 1))
      = (n : ℤ)^4 := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_Icc_succ_top (by omega : 1 ≤ m + 1), ih]
    push_cast
    ring