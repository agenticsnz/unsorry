import Mathlib

theorem gself_pow_three_pow_30_add_pow_fourteen (n : ℤ) : (n^3) ∣ (n^30 + n^14) := by
  exact ⟨n^27 + n^11, by ring⟩
