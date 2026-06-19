import Mathlib

theorem gself_pow_two_pow_30_add_pow_25 (n : ℤ) : (n^2) ∣ (n^30 + n^25) := by
  exact ⟨n^28 + n^23, by ring⟩
