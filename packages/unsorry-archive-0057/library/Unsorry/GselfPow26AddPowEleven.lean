import Mathlib

theorem gself_pow_26_add_pow_eleven (n : ℤ) : (n) ∣ (n^26 + n^11) := by
  exact ⟨n^25 + n^10, by ring⟩
