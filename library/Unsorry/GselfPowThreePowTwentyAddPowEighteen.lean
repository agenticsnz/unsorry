import Mathlib

theorem gself_pow_three_pow_twenty_add_pow_eighteen (n : ℤ) : (n^3) ∣ (n^20 + n^18) := by
  exact ⟨n^17 + n^15, by ring⟩
