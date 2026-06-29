import Mathlib

theorem gself_pow_26_add_pow_ten (n : ℤ) : (n) ∣ (n^26 + n^10) := by
  exact ⟨n^25 + n^9, by ring⟩
