import Mathlib

theorem gself_pow_two_pow_eight_add_pow_four (n : ℤ) : (n^2) ∣ (n^8 + n^4) := by
  exact ⟨n^6 + n^2, by ring⟩
