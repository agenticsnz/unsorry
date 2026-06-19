import Mathlib

theorem gself_pow_two_pow_27_add_pow_twelve (n : ℤ) : (n^2) ∣ (n^27 + n^12) := by
  exact ⟨n^25 + n^10, by ring⟩
