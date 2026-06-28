import Mathlib

theorem gself_pow_three_pow_28_add_pow_25 (n : ℤ) : (n^3) ∣ (n^28 + n^25) := by
  exact ⟨n^25 + n^22, by ring⟩
