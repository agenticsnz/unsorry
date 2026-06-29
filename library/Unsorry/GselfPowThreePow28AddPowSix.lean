import Mathlib

theorem gself_pow_three_pow_28_add_pow_six (n : ℤ) : (n^3) ∣ (n^28 + n^6) := by
  exact ⟨n^25 + n^3, by ring⟩
