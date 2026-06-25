import Mathlib

theorem gself_pow_28_add_pow_three (n : ℤ) : (n) ∣ (n^28 + n^3) := by
  exact ⟨n^27 + n^2, by ring⟩
