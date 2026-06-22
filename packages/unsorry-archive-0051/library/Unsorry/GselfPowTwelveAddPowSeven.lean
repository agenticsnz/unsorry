import Mathlib

theorem gself_pow_twelve_add_pow_seven (n : ℤ) : (n) ∣ (n^12 + n^7) := by
  exact ⟨n^11 + n^6, by ring⟩
