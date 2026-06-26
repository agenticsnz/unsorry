import Mathlib

theorem gself_pow_two_pow_30_add_pow_four (n : ℤ) : (n^2) ∣ (n^30 + n^4) := by
  exact ⟨n^28 + n^2, by ring⟩
