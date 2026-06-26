import Mathlib

theorem gself_pow_two_pow_28_add_pow_22 (n : ℤ) : (n^2) ∣ (n^28 + n^22) := by
  exact ⟨n^26 + n^20, by ring⟩
