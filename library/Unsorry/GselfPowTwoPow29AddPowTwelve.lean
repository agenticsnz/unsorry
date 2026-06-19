import Mathlib

theorem gself_pow_two_pow_29_add_pow_twelve (n : ℤ) : (n^2) ∣ (n^29 + n^12) := by
  exact ⟨n^27 + n^10, by ring⟩
