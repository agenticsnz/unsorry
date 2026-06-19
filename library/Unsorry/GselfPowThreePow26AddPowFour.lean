import Mathlib

theorem gself_pow_three_pow_26_add_pow_four (n : ℤ) : (n^3) ∣ (n^26 + n^4) := by
  exact ⟨n^23 + n, by ring⟩
