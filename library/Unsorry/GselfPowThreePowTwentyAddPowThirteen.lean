import Mathlib

theorem gself_pow_three_pow_twenty_add_pow_thirteen (n : ℤ) : (n^3) ∣ (n^20 + n^13) := by
  exact ⟨n^17 + n^10, by ring⟩
