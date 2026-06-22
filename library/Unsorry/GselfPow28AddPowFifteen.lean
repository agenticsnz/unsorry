import Mathlib

theorem gself_pow_28_add_pow_fifteen (n : ℤ) : (n) ∣ (n^28 + n^15) := by
  exact ⟨n^27 + n^14, by ring⟩
