import Mathlib

theorem gself_pow_27_add_pow_nineteen (n : ℤ) : (n) ∣ (n^27 + n^19) := by
  exact ⟨n^26 + n^18, by ring⟩
