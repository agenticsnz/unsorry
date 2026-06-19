import Mathlib

theorem gself_pow_25_add_pow_thirteen (n : ℤ) : (n) ∣ (n^25 + n^13) := by
  exact ⟨n^24 + n^12, by ring⟩
