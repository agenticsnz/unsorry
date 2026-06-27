import Mathlib

theorem gself_pow_two_pow_26_add_pow_twelve (n : ℤ) : (n^2) ∣ (n^26 + n^12) := by
  exact ⟨n^24 + n^10, by ring⟩
