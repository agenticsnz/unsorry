import Mathlib

theorem gself_pow_27_add_pow_26 (n : ℤ) : (n) ∣ (n^27 + n^26) := by
  exact ⟨n^26 + n^25, by ring⟩
