import Mathlib

theorem gself_pow_two_pow_27_add_pow_eight (n : ℤ) : (n^2) ∣ (n^27 + n^8) := by
  exact ⟨n^25 + n^6, by ring⟩
