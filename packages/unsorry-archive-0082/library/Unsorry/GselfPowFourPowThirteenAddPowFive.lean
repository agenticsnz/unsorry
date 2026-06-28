import Mathlib

theorem gself_pow_four_pow_thirteen_add_pow_five (n : ℤ) : (n^4) ∣ (n^13 + n^5) := by
  exact ⟨n^9 + n, by ring⟩
