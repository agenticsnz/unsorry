import Mathlib

theorem gself_pow_nine_add_pow_eight (n : ℤ) : (n) ∣ (n^9 + n^8) := by
  exact ⟨n^8 + n^7, by ring⟩
