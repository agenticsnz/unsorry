import Mathlib

theorem gself_pow_thirteen_add_pow_two (n : ℤ) : (n) ∣ (n^13 + n^2) := by
  exact ⟨n^12 + n, by ring⟩
