import Mathlib

theorem gself_pow_28_add_pow_23 (n : ℤ) : (n) ∣ (n^28 + n^23) := by
  exact ⟨n^27 + n^22, by ring⟩
