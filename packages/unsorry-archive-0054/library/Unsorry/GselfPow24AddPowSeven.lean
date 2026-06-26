import Mathlib

theorem gself_pow_24_add_pow_seven (n : ℤ) : (n) ∣ (n^24 + n^7) := by
  exact ⟨n^23 + n^6, by ring⟩
