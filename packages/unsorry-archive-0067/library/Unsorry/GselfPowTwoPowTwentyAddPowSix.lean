import Mathlib

theorem gself_pow_two_pow_twenty_add_pow_six (n : ℤ) : (n^2) ∣ (n^20 + n^6) := by
  exact ⟨n^18 + n^4, by ring⟩
