import Mathlib

theorem gself_pow_twenty_add_pow_eighteen (n : ℤ) : (n) ∣ (n^20 + n^18) := by
  exact ⟨n^19 + n^17, by ring⟩
