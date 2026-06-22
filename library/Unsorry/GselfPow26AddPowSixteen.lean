import Mathlib

theorem gself_pow_26_add_pow_sixteen (n : ℤ) : (n) ∣ (n^26 + n^16) := by
  exact ⟨n^25 + n^15, by ring⟩
