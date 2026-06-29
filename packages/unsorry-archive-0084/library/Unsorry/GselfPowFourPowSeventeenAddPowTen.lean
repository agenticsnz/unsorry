import Mathlib

theorem gself_pow_four_pow_seventeen_add_pow_ten (n : ℤ) : (n^4) ∣ (n^17 + n^10) := by
  exact ⟨n^13 + n^6, by ring⟩
