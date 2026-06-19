import Mathlib

theorem gself_pow_two_pow_25_add_pow_six (n : ℤ) : (n^2) ∣ (n^25 + n^6) := by
  exact ⟨n^23 + n^4, by ring⟩
