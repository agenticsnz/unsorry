import Mathlib

theorem gself_pow_two_pow_30_add_pow_nine (n : ℤ) : (n^2) ∣ (n^30 + n^9) := by
  exact ⟨n^28 + n^7, by ring⟩
