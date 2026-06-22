import Mathlib

theorem gself_pow_28_add_pow_22 (n : ℤ) : (n) ∣ (n^28 + n^22) := by
  exact ⟨n^27 + n^21, by ring⟩
