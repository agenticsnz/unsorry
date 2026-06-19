import Mathlib

theorem gself_pow_27_add_pow_six (n : ℤ) : (n) ∣ (n^27 + n^6) := by
  exact ⟨n^26 + n^5, by ring⟩
