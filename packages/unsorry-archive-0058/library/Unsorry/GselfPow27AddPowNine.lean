import Mathlib

theorem gself_pow_27_add_pow_nine (n : ℤ) : (n) ∣ (n^27 + n^9) := by
  exact ⟨n^26 + n^8, by ring⟩
