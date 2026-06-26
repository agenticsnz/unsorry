import Mathlib

theorem gself_pow_25_add_pow_sixteen (n : ℤ) : (n) ∣ (n^25 + n^16) := by
  exact ⟨n^24 + n^15, by ring⟩
