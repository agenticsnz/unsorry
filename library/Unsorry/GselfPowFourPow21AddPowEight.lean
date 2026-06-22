import Mathlib

theorem gself_pow_four_pow_21_add_pow_eight (n : ℤ) : (n^4) ∣ (n^21 + n^8) := by
  exact ⟨n^17 + n^4, by ring⟩
