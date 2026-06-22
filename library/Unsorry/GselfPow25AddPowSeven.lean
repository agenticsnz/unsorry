import Mathlib

theorem gself_pow_25_add_pow_seven (n : ℤ) : (n) ∣ (n^25 + n^7) := by
  exact ⟨n^24 + n^6, by ring⟩
