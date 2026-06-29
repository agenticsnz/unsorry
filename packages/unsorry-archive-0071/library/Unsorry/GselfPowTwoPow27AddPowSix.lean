import Mathlib

theorem gself_pow_two_pow_27_add_pow_six (n : ℤ) : (n^2) ∣ (n^27 + n^6) := by
  exact ⟨n^25 + n^4, by ring⟩
