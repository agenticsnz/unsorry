import Mathlib

theorem gself_pow_two_pow_twenty_add_pow_nineteen (n : ℤ) : (n^2) ∣ (n^20 + n^19) := by
  exact ⟨n^18 + n^17, by ring⟩
