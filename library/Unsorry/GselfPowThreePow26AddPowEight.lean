import Mathlib

theorem gself_pow_three_pow_26_add_pow_eight (n : ℤ) : (n^3) ∣ (n^26 + n^8) := by
  exact ⟨n^23 + n^5, by ring⟩
