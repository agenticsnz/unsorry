import Mathlib

theorem gself_pow_24_add_pow_21 (n : ℤ) : (n) ∣ (n^24 + n^21) := by
  exact ⟨n^23 + n^20, by ring⟩
