import Mathlib

theorem gself_pow_21_add_pow_thirteen (n : ℤ) : (n) ∣ (n^21 + n^13) := by
  exact ⟨n^20 + n^12, by ring⟩
