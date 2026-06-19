import Mathlib

theorem gself_pow_two_pow_23_add_pow_twelve (n : ℤ) : (n^2) ∣ (n^23 + n^12) := by
  exact ⟨n^21 + n^10, by ring⟩
