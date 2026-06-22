import Mathlib

theorem gself_pow_three_pow_23_add_pow_fourteen (n : ℤ) : (n^3) ∣ (n^23 + n^14) := by
  exact ⟨n^20 + n^11, by ring⟩
