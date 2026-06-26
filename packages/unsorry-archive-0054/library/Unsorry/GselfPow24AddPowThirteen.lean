import Mathlib

theorem gself_pow_24_add_pow_thirteen (n : ℤ) : (n) ∣ (n^24 + n^13) := by
  exact ⟨n^23 + n^12, by ring⟩
