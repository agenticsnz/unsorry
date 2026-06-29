import Mathlib

theorem gself_pow_25_add_pow_six (n : ℤ) : (n) ∣ (n^25 + n^6) := by
  exact ⟨n^24 + n^5, by ring⟩
