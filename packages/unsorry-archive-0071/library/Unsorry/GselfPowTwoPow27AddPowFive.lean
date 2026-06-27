import Mathlib

theorem gself_pow_two_pow_27_add_pow_five (n : ℤ) : (n^2) ∣ (n^27 + n^5) := by
  exact ⟨n^25 + n^3, by ring⟩
