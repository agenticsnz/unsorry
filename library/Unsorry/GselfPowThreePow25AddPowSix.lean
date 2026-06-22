import Mathlib

theorem gself_pow_three_pow_25_add_pow_six (n : ℤ) : (n^3) ∣ (n^25 + n^6) := by
  exact ⟨n^22 + n^3, by ring⟩
