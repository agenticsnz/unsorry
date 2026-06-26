import Mathlib

theorem gself_pow_two_pow_28_add_pow_seven (n : ℤ) : (n^2) ∣ (n^28 + n^7) := by
  exact ⟨n^26 + n^5, by ring⟩
