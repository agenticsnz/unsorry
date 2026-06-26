import Mathlib

theorem gself_pow_28_add_pow_twelve (n : ℤ) : (n) ∣ (n^28 + n^12) := by
  exact ⟨n^27 + n^11, by ring⟩
