import Mathlib

theorem gself_pow_21_add_pow_nineteen (n : ℤ) : (n) ∣ (n^21 + n^19) := by
  exact ⟨n^20 + n^18, by ring⟩
