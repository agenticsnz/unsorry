import Mathlib

theorem gself_pow_twelve_add_pow_eight (n : ℤ) : (n) ∣ (n^12 + n^8) := by
  exact ⟨n^11 + n^7, by ring⟩
