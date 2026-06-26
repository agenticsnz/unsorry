import Mathlib

theorem gself_pow_25_add_pow_five (n : ℤ) : (n) ∣ (n^25 + n^5) := by
  exact ⟨n^24 + n^4, by ring⟩
