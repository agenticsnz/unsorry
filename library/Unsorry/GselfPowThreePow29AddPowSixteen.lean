import Mathlib

theorem gself_pow_three_pow_29_add_pow_sixteen (n : ℤ) : (n^3) ∣ (n^29 + n^16) := by
  exact ⟨n^26 + n^13, by ring⟩
