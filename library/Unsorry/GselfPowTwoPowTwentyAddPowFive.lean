import Mathlib

theorem gself_pow_two_pow_twenty_add_pow_five (n : ℤ) : (n^2) ∣ (n^20 + n^5) := by
  exact ⟨n^18 + n^3, by ring⟩
