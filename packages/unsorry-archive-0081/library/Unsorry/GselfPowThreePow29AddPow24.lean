import Mathlib

theorem gself_pow_three_pow_29_add_pow_24 (n : ℤ) : (n^3) ∣ (n^29 + n^24) := by
  exact ⟨n^26 + n^21, by ring⟩
