import Mathlib

theorem gself_pow_24_add_pow_twenty (n : ℤ) : (n) ∣ (n^24 + n^20) := by
  exact ⟨n^23 + n^19, by ring⟩
