import Mathlib

theorem gself_pow_eight_add_pow_six (n : ℤ) : (n) ∣ (n^8 + n^6) := by
  exact ⟨n^7 + n^5, by ring⟩
