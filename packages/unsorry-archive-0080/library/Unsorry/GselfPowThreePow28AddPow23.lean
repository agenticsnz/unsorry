import Mathlib

theorem gself_pow_three_pow_28_add_pow_23 (n : ℤ) : (n^3) ∣ (n^28 + n^23) := by
  exact ⟨n^25 + n^20, by ring⟩
