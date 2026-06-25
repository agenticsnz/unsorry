import Mathlib

theorem gself_pow_24_add_pow_fourteen (n : ℤ) : (n) ∣ (n^24 + n^14) := by
  exact ⟨n^23 + n^13, by ring⟩
