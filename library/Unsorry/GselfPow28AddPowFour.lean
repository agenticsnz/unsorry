import Mathlib

theorem gself_pow_28_add_pow_four (n : ℤ) : (n) ∣ (n^28 + n^4) := by
  exact ⟨n^27 + n^3, by ring⟩
