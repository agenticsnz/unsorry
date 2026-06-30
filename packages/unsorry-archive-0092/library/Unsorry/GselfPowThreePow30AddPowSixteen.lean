import Mathlib

theorem gself_pow_three_pow_30_add_pow_sixteen (n : ℤ) : (n^3) ∣ (n^30 + n^16) := by
  exact ⟨n^27 + n^13, by ring⟩
