import Mathlib

theorem gself_pow_24_add_pow_twelve (n : ℤ) : (n) ∣ (n^24 + n^12) := by
  exact ⟨n^23 + n^11, by ring⟩
