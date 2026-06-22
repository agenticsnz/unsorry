import Mathlib

theorem gself_pow_four_pow_21_add_pow_four (n : ℤ) : (n^4) ∣ (n^21 + n^4) := by
  exact ⟨n^17 + 1, by ring⟩
