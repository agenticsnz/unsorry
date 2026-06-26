import Mathlib

theorem gself_pow_four_pow_seventeen_add_pow_twelve (n : ℤ) : (n^4) ∣ (n^17 + n^12) := by
  exact ⟨n^13 + n^8, by ring⟩
