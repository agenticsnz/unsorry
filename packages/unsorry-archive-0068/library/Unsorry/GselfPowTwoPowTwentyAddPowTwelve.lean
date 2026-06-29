import Mathlib

theorem gself_pow_two_pow_twenty_add_pow_twelve (n : ℤ) : (n^2) ∣ (n^20 + n^12) := by
  exact ⟨n^18 + n^10, by ring⟩
