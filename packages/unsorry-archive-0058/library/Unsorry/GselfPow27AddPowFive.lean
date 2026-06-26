import Mathlib

theorem gself_pow_27_add_pow_five (n : ℤ) : (n) ∣ (n^27 + n^5) := by
  exact ⟨n^26 + n^4, by ring⟩
