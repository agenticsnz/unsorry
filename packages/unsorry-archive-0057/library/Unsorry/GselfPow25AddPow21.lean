import Mathlib

theorem gself_pow_25_add_pow_21 (n : ℤ) : (n) ∣ (n^25 + n^21) := by
  exact ⟨n^24 + n^20, by ring⟩
