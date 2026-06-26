import Mathlib

theorem gself_pow_27_add_pow_twelve (n : ℤ) : (n) ∣ (n^27 + n^12) := by
  exact ⟨n^26 + n^11, by ring⟩
