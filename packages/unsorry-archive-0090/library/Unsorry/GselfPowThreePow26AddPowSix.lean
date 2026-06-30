import Mathlib

theorem gself_pow_three_pow_26_add_pow_six (n : ℤ) : (n^3) ∣ (n^26 + n^6) := by
  exact ⟨n^23 + n^3, by ring⟩
