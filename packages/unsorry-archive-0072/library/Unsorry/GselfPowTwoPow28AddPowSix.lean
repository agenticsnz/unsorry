import Mathlib

theorem gself_pow_two_pow_28_add_pow_six (n : ℤ) : (n^2) ∣ (n^28 + n^6) := by
  exact ⟨n^26 + n^4, by ring⟩
