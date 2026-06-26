import Mathlib

theorem gself_pow_27_add_pow_sixteen (n : ℤ) : (n) ∣ (n^27 + n^16) := by
  exact ⟨n^26 + n^15, by ring⟩
