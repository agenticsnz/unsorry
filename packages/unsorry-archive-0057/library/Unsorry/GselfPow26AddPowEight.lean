import Mathlib

theorem gself_pow_26_add_pow_eight (n : ℤ) : (n) ∣ (n^26 + n^8) := by
  exact ⟨n^25 + n^7, by ring⟩
