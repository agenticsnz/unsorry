import Mathlib

theorem gself_pow_26_add_pow_five (n : ℤ) : (n) ∣ (n^26 + n^5) := by
  exact ⟨n^25 + n^4, by ring⟩
