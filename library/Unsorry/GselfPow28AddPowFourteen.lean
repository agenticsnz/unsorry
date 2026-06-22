import Mathlib

theorem gself_pow_28_add_pow_fourteen (n : ℤ) : (n) ∣ (n^28 + n^14) := by
  exact ⟨n^27 + n^13, by ring⟩
