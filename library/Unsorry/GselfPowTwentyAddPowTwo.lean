import Mathlib

theorem gself_pow_twenty_add_pow_two (n : ℤ) : (n) ∣ (n^20 + n^2) := by
  exact ⟨n^19 + n, by ring⟩
