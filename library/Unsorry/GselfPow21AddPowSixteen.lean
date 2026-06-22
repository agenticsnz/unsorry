import Mathlib

theorem gself_pow_21_add_pow_sixteen (n : ℤ) : (n) ∣ (n^21 + n^16) := by
  exact ⟨n^20 + n^15, by ring⟩
