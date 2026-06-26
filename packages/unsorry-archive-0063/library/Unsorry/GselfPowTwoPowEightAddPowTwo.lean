import Mathlib

theorem gself_pow_two_pow_eight_add_pow_two (n : ℤ) : (n^2) ∣ (n^8 + n^2) := by
  exact ⟨n^6 + 1, by ring⟩
