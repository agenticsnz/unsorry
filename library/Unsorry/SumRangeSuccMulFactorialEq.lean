import Mathlib

theorem sum_range_succ_mul_factorial_eq (n : ℕ) : ∑ k ∈ Finset.range n, (k + 1) * Nat.factorial (k + 1) = Nat.factorial (n + 1) - 1 := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    have h1 : 1 ≤ Nat.factorial (m + 1) := Nat.factorial_pos _
    have hfac : Nat.factorial (m + 1 + 1) = (m + 1 + 1) * Nat.factorial (m + 1) := by
      rw [Nat.factorial_succ]
    rw [hfac]
    set F := Nat.factorial (m + 1) with hF
    have hexp : (m + 1 + 1) * F = (m + 1) * F + F := by ring
    omega