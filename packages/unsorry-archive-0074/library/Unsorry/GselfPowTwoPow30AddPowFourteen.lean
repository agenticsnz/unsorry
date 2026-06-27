import Mathlib

theorem gself_pow_two_pow_30_add_pow_fourteen (n : ℤ) : (n^2) ∣ (n^30 + n^14) := by
  exact ⟨n^28 + n^12, by ring⟩
