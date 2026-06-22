import Mathlib

theorem gself_pow_four_pow_eight_add_pow_four (n : ℤ) : (n^4) ∣ (n^8 + n^4) := by
  exact ⟨n^4 + 1, by ring⟩
