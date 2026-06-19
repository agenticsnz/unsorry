import Mathlib

theorem gself_pow_25_add_pow_nine (n : ℤ) : (n) ∣ (n^25 + n^9) := by
  exact ⟨n^24 + n^8, by ring⟩
