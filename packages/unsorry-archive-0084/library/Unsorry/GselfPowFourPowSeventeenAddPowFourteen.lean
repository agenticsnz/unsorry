import Mathlib

theorem gself_pow_four_pow_seventeen_add_pow_fourteen (n : ℤ) : (n^4) ∣ (n^17 + n^14) := by
  exact ⟨n^13 + n^10, by ring⟩
