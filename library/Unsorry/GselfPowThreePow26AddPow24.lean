import Mathlib

theorem gself_pow_three_pow_26_add_pow_24 (n : ℤ) : (n^3) ∣ (n^26 + n^24) := by
  exact ⟨n^23 + n^21, by ring⟩
