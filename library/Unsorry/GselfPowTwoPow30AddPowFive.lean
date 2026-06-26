import Mathlib

theorem gself_pow_two_pow_30_add_pow_five (n : ℤ) : (n^2) ∣ (n^30 + n^5) := by
  exact ⟨n^28 + n^3, by ring⟩
