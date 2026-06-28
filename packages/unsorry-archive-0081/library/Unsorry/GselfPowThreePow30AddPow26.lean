import Mathlib

theorem gself_pow_three_pow_30_add_pow_26 (n : ℤ) : (n^3) ∣ (n^30 + n^26) := by
  exact ⟨n^27 + n^23, by ring⟩
