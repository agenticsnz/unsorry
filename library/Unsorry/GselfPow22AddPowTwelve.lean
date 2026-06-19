import Mathlib

theorem gself_pow_22_add_pow_twelve (n : ℤ) : (n) ∣ (n^22 + n^12) := by
  exact ⟨n^21 + n^11, by ring⟩
