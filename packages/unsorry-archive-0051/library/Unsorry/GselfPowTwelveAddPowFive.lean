import Mathlib

theorem gself_pow_twelve_add_pow_five (n : ℤ) : (n) ∣ (n^12 + n^5) := by
  exact ⟨n^11 + n^4, by ring⟩
