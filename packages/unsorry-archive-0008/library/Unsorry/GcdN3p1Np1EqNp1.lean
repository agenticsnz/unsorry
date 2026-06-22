import Mathlib

theorem gcd_n3p1_np1_eq_np1 (n : ℕ) : Nat.gcd (n^3 + 1) (n + 1) = n + 1 := by
  have hdvd : (n + 1) ∣ (n ^ 3 + 1) := by
    have h : ((n + 1 : ℕ) : ℤ) ∣ ((n ^ 3 + 1 : ℕ) : ℤ) := by
      push_cast
      exact ⟨(n : ℤ) ^ 2 - n + 1, by ring⟩
    exact_mod_cast h
  exact Nat.gcd_eq_right hdvd
