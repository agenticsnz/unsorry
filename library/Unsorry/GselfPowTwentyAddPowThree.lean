import Mathlib

theorem gself_pow_twenty_add_pow_three (n : ℤ) : (n) ∣ (n^20 + n^3) := by
  exact ⟨n^19 + n^2, by ring⟩
