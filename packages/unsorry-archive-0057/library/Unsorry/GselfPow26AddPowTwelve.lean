import Mathlib

theorem gself_pow_26_add_pow_twelve (n : ℤ) : (n) ∣ (n^26 + n^12) := by
  exact ⟨n^25 + n^11, by ring⟩
