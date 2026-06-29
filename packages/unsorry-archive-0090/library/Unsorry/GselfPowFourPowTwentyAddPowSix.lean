import Mathlib

theorem gself_pow_four_pow_twenty_add_pow_six (n : ℤ) : (n^4) ∣ (n^20 + n^6) := by
  exact ⟨n^16 + n^2, by ring⟩
