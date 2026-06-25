import Mathlib

theorem gself_pow_27_add_pow_25 (n : ℤ) : (n) ∣ (n^27 + n^25) := by
  exact ⟨n^26 + n^24, by ring⟩
