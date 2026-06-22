import Mathlib

theorem gself_pow_28_add_pow_25 (n : ℤ) : (n) ∣ (n^28 + n^25) := by
  exact ⟨n^27 + n^24, by ring⟩
