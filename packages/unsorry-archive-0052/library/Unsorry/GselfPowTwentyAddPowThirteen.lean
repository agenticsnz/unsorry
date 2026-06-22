import Mathlib

theorem gself_pow_twenty_add_pow_thirteen (n : ℤ) : (n) ∣ (n^20 + n^13) := by
  exact ⟨n^19 + n^12, by ring⟩
