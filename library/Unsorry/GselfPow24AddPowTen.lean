import Mathlib

theorem gself_pow_24_add_pow_ten (n : ℤ) : (n) ∣ (n^24 + n^10) := by
  exact ⟨n^23 + n^9, by ring⟩
