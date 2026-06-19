import Mathlib

theorem gself_pow_27_add_pow_ten (n : ℤ) : (n) ∣ (n^27 + n^10) := by
  exact ⟨n^26 + n^9, by ring⟩
