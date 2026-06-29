import Mathlib

theorem gself_pow_two_pow_twenty_add_pow_fifteen (n : ℤ) : (n^2) ∣ (n^20 + n^15) := by
  exact ⟨n^18 + n^13, by ring⟩
