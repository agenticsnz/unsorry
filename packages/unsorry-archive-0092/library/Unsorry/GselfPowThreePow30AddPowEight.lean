import Mathlib

theorem gself_pow_three_pow_30_add_pow_eight (n : ℤ) : (n^3) ∣ (n^30 + n^8) := by
  exact ⟨n^27 + n^5, by ring⟩
