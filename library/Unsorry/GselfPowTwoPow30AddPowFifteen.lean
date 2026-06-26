import Mathlib

theorem gself_pow_two_pow_30_add_pow_fifteen (n : ℤ) : (n^2) ∣ (n^30 + n^15) := by
  exact ⟨n^28 + n^13, by ring⟩
