import Mathlib

theorem gself_pow_24_add_pow_nineteen (n : ℤ) : (n) ∣ (n^24 + n^19) := by
  exact ⟨n^23 + n^18, by ring⟩
