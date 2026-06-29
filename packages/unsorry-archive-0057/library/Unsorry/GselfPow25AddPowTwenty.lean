import Mathlib

theorem gself_pow_25_add_pow_twenty (n : ℤ) : (n) ∣ (n^25 + n^20) := by
  exact ⟨n^24 + n^19, by ring⟩
