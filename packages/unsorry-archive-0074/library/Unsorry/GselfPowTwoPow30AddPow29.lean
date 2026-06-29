import Mathlib

theorem gself_pow_two_pow_30_add_pow_29 (n : ℤ) : (n^2) ∣ (n^30 + n^29) := by
  exact ⟨n^28 + n^27, by ring⟩
