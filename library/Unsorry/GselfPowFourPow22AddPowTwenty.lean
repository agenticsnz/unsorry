import Mathlib

theorem gself_pow_four_pow_22_add_pow_twenty (n : ℤ) : (n^4) ∣ (n^22 + n^20) := by
  exact ⟨n^18 + n^16, by ring⟩
