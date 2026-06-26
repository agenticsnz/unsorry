import Mathlib

theorem gself_pow_25_add_pow_fifteen (n : ℤ) : (n) ∣ (n^25 + n^15) := by
  exact ⟨n^24 + n^14, by ring⟩
