import Mathlib

theorem gself_pow_two_pow_twenty_add_pow_seven (n : ℤ) : (n^2) ∣ (n^20 + n^7) := by
  exact ⟨n^18 + n^5, by ring⟩
