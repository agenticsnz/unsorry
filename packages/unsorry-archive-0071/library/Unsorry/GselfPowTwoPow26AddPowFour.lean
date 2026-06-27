import Mathlib

theorem gself_pow_two_pow_26_add_pow_four (n : ℤ) : (n^2) ∣ (n^26 + n^4) := by
  exact ⟨n^24 + n^2, by ring⟩
