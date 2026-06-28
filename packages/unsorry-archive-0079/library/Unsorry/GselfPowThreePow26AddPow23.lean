import Mathlib

theorem gself_pow_three_pow_26_add_pow_23 (n : ℤ) : (n^3) ∣ (n^26 + n^23) := by
  exact ⟨n^23 + n^20, by ring⟩
