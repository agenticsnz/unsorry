import Mathlib

theorem gself_pow_26_add_pow_25 (n : ℤ) : (n) ∣ (n^26 + n^25) := by
  exact ⟨n^25 + n^24, by ring⟩
