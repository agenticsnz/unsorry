import Mathlib

theorem gself_pow_two_pow_29_add_pow_28 (n : ℤ) : (n^2) ∣ (n^29 + n^28) := by
  exact ⟨n^27 + n^26, by ring⟩
