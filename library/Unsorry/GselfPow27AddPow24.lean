import Mathlib

theorem gself_pow_27_add_pow_24 (n : ℤ) : (n) ∣ (n^27 + n^24) := by
  exact ⟨n^26 + n^23, by ring⟩
