import Mathlib

theorem gself_pow_thirteen_add_pow_six (n : ℤ) : (n) ∣ (n^13 + n^6) := by
  exact ⟨n^12 + n^5, by ring⟩
