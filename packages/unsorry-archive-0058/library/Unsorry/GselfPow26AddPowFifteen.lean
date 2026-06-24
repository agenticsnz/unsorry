import Mathlib

theorem gself_pow_26_add_pow_fifteen (n : ℤ) : (n) ∣ (n^26 + n^15) := by
  exact ⟨n^25 + n^14, by ring⟩
