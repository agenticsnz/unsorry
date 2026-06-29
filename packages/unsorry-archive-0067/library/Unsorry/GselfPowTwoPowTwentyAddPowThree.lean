import Mathlib

theorem gself_pow_two_pow_twenty_add_pow_three (n : ℤ) : (n^2) ∣ (n^20 + n^3) := by
  exact ⟨n^18 + n, by ring⟩
