import Mathlib

theorem gself_pow_four_pow_twenty_add_pow_seventeen (n : ℤ) : (n^4) ∣ (n^20 + n^17) := by
  exact ⟨n^16 + n^13, by ring⟩
