import Mathlib

theorem gself_pow_seventeen_add_pow_fourteen (n : ℤ) : (n) ∣ (n^17 + n^14) := by
  exact ⟨n^16 + n^13, by ring⟩
