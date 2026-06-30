import Mathlib

theorem gself_pow_three_pow_29_add_pow_twenty (n : ℤ) : (n^3) ∣ (n^29 + n^20) := by
  exact ⟨n^26 + n^17, by ring⟩
