import Mathlib

theorem gself_pow_25_add_pow_four (n : ℤ) : (n) ∣ (n^25 + n^4) := by
  exact ⟨n^24 + n^3, by ring⟩
