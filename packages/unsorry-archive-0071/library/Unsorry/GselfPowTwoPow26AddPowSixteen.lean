import Mathlib

theorem gself_pow_two_pow_26_add_pow_sixteen (n : ℤ) : (n^2) ∣ (n^26 + n^16) := by
  exact ⟨n^24 + n^14, by ring⟩
