import Mathlib

theorem gself_pow_26_add_pow_nine (n : ℤ) : (n) ∣ (n^26 + n^9) := by
  exact ⟨n^25 + n^8, by ring⟩
