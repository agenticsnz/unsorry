import Mathlib

theorem gself_pow_three_pow_30_add_pow_28 (n : ℤ) : (n^3) ∣ (n^30 + n^28) := by
  exact ⟨n^27 + n^25, by ring⟩
