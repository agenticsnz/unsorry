import Mathlib

theorem gself_pow_26_add_pow_four (n : ℤ) : (n) ∣ (n^26 + n^4) := by
  exact ⟨n^25 + n^3, by ring⟩
