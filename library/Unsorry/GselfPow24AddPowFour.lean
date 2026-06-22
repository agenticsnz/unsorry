import Mathlib

theorem gself_pow_24_add_pow_four (n : ℤ) : (n) ∣ (n^24 + n^4) := by
  exact ⟨n^23 + n^3, by ring⟩
