import Mathlib

theorem gcd_4n3_5n4_eq_one (n : ℤ) :
    Int.gcd (4 * n + 3) (5 * n + 4) = 1 := by
  rw [← Int.isCoprime_iff_gcd_eq_one]
  exact ⟨-5, 4, by ring⟩
