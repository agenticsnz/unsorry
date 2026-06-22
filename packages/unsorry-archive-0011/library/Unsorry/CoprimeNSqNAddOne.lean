import Mathlib

theorem coprime_n_sq_n_add_one (n : ℕ) : Nat.Coprime n (n ^ 2 + n + 1)
  := by
    rw [Nat.coprime_iff_gcd_eq_one]
    have h1 : n ^ 2 + n + 1 = n * (n + 1) + 1 := by ring
    rw [h1]
    simp    