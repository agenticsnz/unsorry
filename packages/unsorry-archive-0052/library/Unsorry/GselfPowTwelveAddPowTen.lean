import Mathlib

theorem gself_pow_twelve_add_pow_ten (n : ℤ) : (n) ∣ (n^12 + n^10) := by
  exact ⟨n^11 + n^9, by ring⟩
