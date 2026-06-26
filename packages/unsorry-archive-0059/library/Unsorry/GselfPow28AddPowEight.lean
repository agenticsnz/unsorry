import Mathlib

theorem gself_pow_28_add_pow_eight (n : ℤ) : (n) ∣ (n^28 + n^8) := by
  exact ⟨n^27 + n^7, by ring⟩
