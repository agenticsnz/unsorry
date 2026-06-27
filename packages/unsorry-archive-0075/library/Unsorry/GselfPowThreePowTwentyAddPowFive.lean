import Mathlib

theorem gself_pow_three_pow_twenty_add_pow_five (n : ℤ) : (n^3) ∣ (n^20 + n^5) := by
  exact ⟨n^17 + n^2, by ring⟩
