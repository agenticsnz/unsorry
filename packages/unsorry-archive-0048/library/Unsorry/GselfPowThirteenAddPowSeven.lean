import Mathlib

theorem gself_pow_thirteen_add_pow_seven (n : ℤ) : (n) ∣ (n^13 + n^7) := by
  exact ⟨n^12 + n^6, by ring⟩
