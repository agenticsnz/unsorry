import Mathlib

theorem gself_pow_four_pow_22_add_pow_seven (n : ℤ) : (n^4) ∣ (n^22 + n^7) := by
  exact ⟨n^18 + n^3, by ring⟩
