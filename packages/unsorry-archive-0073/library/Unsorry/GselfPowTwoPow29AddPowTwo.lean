import Mathlib

theorem gself_pow_two_pow_29_add_pow_two (n : ℤ) : (n^2) ∣ (n^29 + n^2) := by
  exact ⟨n^27 + 1, by ring⟩
