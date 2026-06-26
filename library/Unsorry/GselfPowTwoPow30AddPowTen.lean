import Mathlib

theorem gself_pow_two_pow_30_add_pow_ten (n : ℤ) : (n^2) ∣ (n^30 + n^10) := by
  exact ⟨n^28 + n^8, by ring⟩
