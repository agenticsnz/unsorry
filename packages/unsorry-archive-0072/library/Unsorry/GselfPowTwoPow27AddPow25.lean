import Mathlib

theorem gself_pow_two_pow_27_add_pow_25 (n : ℤ) : (n^2) ∣ (n^27 + n^25) := by
  exact ⟨n^25 + n^23, by ring⟩
