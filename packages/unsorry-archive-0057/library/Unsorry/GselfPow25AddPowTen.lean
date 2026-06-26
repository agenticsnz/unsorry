import Mathlib

theorem gself_pow_25_add_pow_ten (n : ℤ) : (n) ∣ (n^25 + n^10) := by
  exact ⟨n^24 + n^9, by ring⟩
