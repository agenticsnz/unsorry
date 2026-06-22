import Mathlib

theorem sum_range_k_div_succ_factorial_telescope (n : ℕ) : (∑ k ∈ Finset.range n, (k : ℚ) / Nat.factorial (k + 1)) = 1 - 1 / Nat.factorial n := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    have hm : (Nat.factorial m : ℚ) ≠ 0 := by
      exact_mod_cast Nat.factorial_ne_zero m
    have hm1 : (Nat.factorial (m + 1) : ℚ) ≠ 0 := by
      exact_mod_cast Nat.factorial_ne_zero (m + 1)
    rw [Nat.factorial_succ]
    push_cast
    field_simp
    ring