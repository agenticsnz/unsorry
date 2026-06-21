import Mathlib

theorem gself_pow_eight_add_pow_seven (n : ℤ) : (n) ∣ (n^8 + n^7) := by
  exact ⟨n^7 + n^6, by ring⟩
