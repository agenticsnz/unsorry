import Mathlib

theorem gself_pow_two_pow_twenty_add_pow_two (n : ℤ) : (n^2) ∣ (n^20 + n^2) := by
  exact ⟨n^18 + 1, by ring⟩
