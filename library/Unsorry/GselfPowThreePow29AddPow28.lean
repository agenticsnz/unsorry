import Mathlib

theorem gself_pow_three_pow_29_add_pow_28 (n : ℤ) : (n^3) ∣ (n^29 + n^28) := by
  exact ⟨n^26 + n^25, by ring⟩
