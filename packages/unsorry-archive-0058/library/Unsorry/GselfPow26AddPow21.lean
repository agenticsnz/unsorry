import Mathlib

theorem gself_pow_26_add_pow_21 (n : ℤ) : (n) ∣ (n^26 + n^21) := by
  exact ⟨n^25 + n^20, by ring⟩
