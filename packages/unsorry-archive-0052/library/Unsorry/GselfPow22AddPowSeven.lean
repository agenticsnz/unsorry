import Mathlib

theorem gself_pow_22_add_pow_seven (n : ℤ) : (n) ∣ (n^22 + n^7) := by
  exact ⟨n^21 + n^6, by ring⟩
