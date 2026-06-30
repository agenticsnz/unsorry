import Mathlib

theorem gself_pow_three_pow_seventeen_add_pow_fourteen (n : ℤ) : (n^3) ∣ (n^17 + n^14) := by
  exact ⟨n^14 + n^11, by ring⟩
