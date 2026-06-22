import Mathlib

theorem gself_pow_twenty_add_pow_seven (n : ℤ) : (n) ∣ (n^20 + n^7) := by
  exact ⟨n^19 + n^6, by ring⟩
