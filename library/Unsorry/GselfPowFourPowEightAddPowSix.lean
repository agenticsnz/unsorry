import Mathlib

theorem gself_pow_four_pow_eight_add_pow_six (n : ℤ) : (n^4) ∣ (n^8 + n^6) := by
  exact ⟨n^4 + n^2, by ring⟩
