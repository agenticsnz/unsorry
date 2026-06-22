import Mathlib

theorem gself_pow_four_pow_seventeen_add_pow_thirteen (n : ℤ) : (n^4) ∣ (n^17 + n^13) := by
  exact ⟨n^13 + n^9, by ring⟩
