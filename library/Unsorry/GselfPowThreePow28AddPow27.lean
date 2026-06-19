import Mathlib

theorem gself_pow_three_pow_28_add_pow_27 (n : ℤ) : (n^3) ∣ (n^28 + n^27) := by
  exact ⟨n^25 + n^24, by ring⟩
