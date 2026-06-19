import Mathlib

theorem gself_pow_two_pow_29_add_pow_nine (n : ℤ) : (n^2) ∣ (n^29 + n^9) := by
  exact ⟨n^27 + n^7, by ring⟩
