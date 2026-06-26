import Mathlib

theorem gself_pow_27_add_pow_four (n : ℤ) : (n) ∣ (n^27 + n^4) := by
  exact ⟨n^26 + n^3, by ring⟩
