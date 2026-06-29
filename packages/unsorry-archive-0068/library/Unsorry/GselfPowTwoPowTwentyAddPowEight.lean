import Mathlib

theorem gself_pow_two_pow_twenty_add_pow_eight (n : ℤ) : (n^2) ∣ (n^20 + n^8) := by
  exact ⟨n^18 + n^6, by ring⟩
