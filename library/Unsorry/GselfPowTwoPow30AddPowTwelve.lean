import Mathlib

theorem gself_pow_two_pow_30_add_pow_twelve (n : ℤ) : (n^2) ∣ (n^30 + n^12) := by
  exact ⟨n^28 + n^10, by ring⟩
