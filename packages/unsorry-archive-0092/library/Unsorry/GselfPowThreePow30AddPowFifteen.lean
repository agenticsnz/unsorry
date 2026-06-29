import Mathlib

theorem gself_pow_three_pow_30_add_pow_fifteen (n : ℤ) : (n^3) ∣ (n^30 + n^15) := by
  exact ⟨n^27 + n^12, by ring⟩
