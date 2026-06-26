import Mathlib

theorem gself_pow_23_add_pow_nineteen (n : ℤ) : (n) ∣ (n^23 + n^19) := by
  exact ⟨n^22 + n^18, by ring⟩
