import Mathlib

theorem gself_pow_twenty_add_pow_seventeen (n : ℤ) : (n) ∣ (n^20 + n^17) := by
  exact ⟨n^19 + n^16, by ring⟩
