import Mathlib

theorem gself_pow_24_add_pow_eleven (n : ℤ) : (n) ∣ (n^24 + n^11) := by
  exact ⟨n^23 + n^10, by ring⟩
