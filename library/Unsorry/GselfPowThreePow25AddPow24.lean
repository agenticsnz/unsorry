import Mathlib

theorem gself_pow_three_pow_25_add_pow_24 (n : ℤ) : (n^3) ∣ (n^25 + n^24) := by
  exact ⟨n^22 + n^21, by ring⟩
