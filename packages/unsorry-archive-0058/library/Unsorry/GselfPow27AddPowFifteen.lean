import Mathlib

theorem gself_pow_27_add_pow_fifteen (n : ℤ) : (n) ∣ (n^27 + n^15) := by
  exact ⟨n^26 + n^14, by ring⟩
