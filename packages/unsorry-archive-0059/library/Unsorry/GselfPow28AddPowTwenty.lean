import Mathlib

theorem gself_pow_28_add_pow_twenty (n : ℤ) : (n) ∣ (n^28 + n^20) := by
  exact ⟨n^27 + n^19, by ring⟩
