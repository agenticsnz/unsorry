import Mathlib

theorem gself_pow_28_add_pow_nineteen (n : ℤ) : (n) ∣ (n^28 + n^19) := by
  exact ⟨n^27 + n^18, by ring⟩
