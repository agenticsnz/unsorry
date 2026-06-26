import Mathlib

theorem gself_pow_28_add_pow_sixteen (n : ℤ) : (n) ∣ (n^28 + n^16) := by
  exact ⟨n^27 + n^15, by ring⟩
