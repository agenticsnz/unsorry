import Mathlib

theorem gself_pow_three_pow_twenty_add_pow_four (n : ℤ) : (n^3) ∣ (n^20 + n^4) := by
  exact ⟨n^17 + n, by ring⟩
