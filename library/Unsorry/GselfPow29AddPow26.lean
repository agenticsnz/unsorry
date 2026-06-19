import Mathlib

theorem gself_pow_29_add_pow_26 (n : ℤ) : (n) ∣ (n^29 + n^26) := by
  exact ⟨n^28 + n^25, by ring⟩
