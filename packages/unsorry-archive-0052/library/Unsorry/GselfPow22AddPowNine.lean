import Mathlib

theorem gself_pow_22_add_pow_nine (n : ℤ) : (n) ∣ (n^22 + n^9) := by
  exact ⟨n^21 + n^8, by ring⟩
