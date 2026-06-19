import Mathlib

theorem gself_pow_three_pow_25_add_pow_eight (n : ℤ) : (n^3) ∣ (n^25 + n^8) := by
  exact ⟨n^22 + n^5, by ring⟩
