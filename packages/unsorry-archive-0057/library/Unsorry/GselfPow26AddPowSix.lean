import Mathlib

theorem gself_pow_26_add_pow_six (n : ℤ) : (n) ∣ (n^26 + n^6) := by
  exact ⟨n^25 + n^5, by ring⟩
