import Mathlib

theorem gself_pow_three_pow_22_add_pow_six (n : ℤ) : (n^3) ∣ (n^22 + n^6) := by
  exact ⟨n^19 + n^3, by ring⟩
