import Mathlib

theorem gself_pow_28_add_pow_26 (n : ℤ) : (n) ∣ (n^28 + n^26) := by
  exact ⟨n^27 + n^25, by ring⟩
