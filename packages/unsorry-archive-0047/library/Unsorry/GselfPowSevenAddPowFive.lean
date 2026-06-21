import Mathlib

theorem gself_pow_seven_add_pow_five (n : ℤ) : (n) ∣ (n^7 + n^5) := by
  exact ⟨n^6 + n^4, by ring⟩
