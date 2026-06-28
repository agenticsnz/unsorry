import Mathlib

theorem gself_pow_four_pow_21_add_pow_eleven (n : ℤ) : (n^4) ∣ (n^21 + n^11) := by
  exact ⟨n^17 + n^7, by ring⟩
