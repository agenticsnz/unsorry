import Mathlib

theorem gself_pow_four_pow_21_add_pow_six (n : ℤ) : (n^4) ∣ (n^21 + n^6) := by
  exact ⟨n^17 + n^2, by ring⟩
