import Mathlib

theorem gself_pow_24_add_pow_five (n : ℤ) : (n) ∣ (n^24 + n^5) := by
  exact ⟨n^23 + n^4, by ring⟩
