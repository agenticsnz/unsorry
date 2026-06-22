import Mathlib

theorem gself_pow_22_add_pow_eight (n : ℤ) : (n) ∣ (n^22 + n^8) := by
  exact ⟨n^21 + n^7, by ring⟩
