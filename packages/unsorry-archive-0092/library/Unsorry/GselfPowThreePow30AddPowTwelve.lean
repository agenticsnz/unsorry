import Mathlib

theorem gself_pow_three_pow_30_add_pow_twelve (n : ℤ) : (n^3) ∣ (n^30 + n^12) := by
  exact ⟨n^27 + n^9, by ring⟩
