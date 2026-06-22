import Mathlib

theorem gself_pow_26_add_pow_seven (n : ℤ) : (n) ∣ (n^26 + n^7) := by
  exact ⟨n^25 + n^6, by ring⟩
