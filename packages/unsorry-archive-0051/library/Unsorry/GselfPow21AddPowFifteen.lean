import Mathlib

theorem gself_pow_21_add_pow_fifteen (n : ℤ) : (n) ∣ (n^21 + n^15) := by
  exact ⟨n^20 + n^14, by ring⟩
