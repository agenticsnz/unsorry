import Mathlib

theorem gself_pow_two_pow_twenty_add_pow_eleven (n : ℤ) : (n^2) ∣ (n^20 + n^11) := by
  exact ⟨n^18 + n^9, by ring⟩
