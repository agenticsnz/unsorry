import Mathlib

theorem gself_pow_four_pow_seventeen_add_pow_seven (n : ℤ) : (n^4) ∣ (n^17 + n^7) := by
  exact ⟨n^13 + n^3, by ring⟩
