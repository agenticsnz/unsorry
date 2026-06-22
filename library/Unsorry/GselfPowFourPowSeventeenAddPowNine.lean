import Mathlib

theorem gself_pow_four_pow_seventeen_add_pow_nine (n : ℤ) : (n^4) ∣ (n^17 + n^9) := by
  exact ⟨n^13 + n^5, by ring⟩
