import Mathlib

theorem sum_range_succ_div_factorial_add_two_telescope (n : ℕ) : (∑ k ∈ Finset.range n, ((k : ℚ) + 1) / Nat.factorial (k + 2)) = 1 - 1 / Nat.factorial (n + 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    have hf2 : (Nat.factorial (m + 2) : ℚ) = ((m : ℚ) + 2) * Nat.factorial (m + 1) := by
      rw [Nat.factorial_succ]
      push_cast
      ring
    have h1 : (Nat.factorial (m + 1) : ℚ) ≠ 0 := by
      exact_mod_cast Nat.factorial_ne_zero (m + 1)
    have h2 : (Nat.factorial (m + 2) : ℚ) ≠ 0 := by
      exact_mod_cast Nat.factorial_ne_zero (m + 2)
    rw [hf2]
    field_simp
    ring