import Mathlib

theorem gself_pow_28_add_pow_nine (n : ℤ) : (n) ∣ (n^28 + n^9) := by
  exact ⟨n^27 + n^8, by ring⟩
