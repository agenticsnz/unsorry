import Mathlib

theorem gself_pow_two_pow_21_add_pow_twenty (n : ℤ) : (n^2) ∣ (n^21 + n^20) := by
  exact ⟨n^19 + n^18, by ring⟩
