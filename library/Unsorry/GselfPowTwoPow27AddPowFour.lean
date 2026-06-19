import Mathlib

theorem gself_pow_two_pow_27_add_pow_four (n : ℤ) : (n^2) ∣ (n^27 + n^4) := by
  exact ⟨n^25 + n^2, by ring⟩
