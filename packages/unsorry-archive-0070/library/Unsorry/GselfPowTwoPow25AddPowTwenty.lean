import Mathlib

theorem gself_pow_two_pow_25_add_pow_twenty (n : ℤ) : (n^2) ∣ (n^25 + n^20) := by
  exact ⟨n^23 + n^18, by ring⟩
