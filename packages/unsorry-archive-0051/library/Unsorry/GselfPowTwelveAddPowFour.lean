import Mathlib

theorem gself_pow_twelve_add_pow_four (n : ℤ) : (n) ∣ (n^12 + n^4) := by
  exact ⟨n^11 + n^3, by ring⟩
