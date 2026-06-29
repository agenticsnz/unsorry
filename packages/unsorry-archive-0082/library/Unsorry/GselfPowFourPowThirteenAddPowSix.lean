import Mathlib

theorem gself_pow_four_pow_thirteen_add_pow_six (n : ℤ) : (n^4) ∣ (n^13 + n^6) := by
  exact ⟨n^9 + n^2, by ring⟩
