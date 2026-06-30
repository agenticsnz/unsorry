import Mathlib

theorem gself_pow_three_pow_seventeen_add_pow_thirteen (n : ℤ) : (n^3) ∣ (n^17 + n^13) := by
  exact ⟨n^14 + n^10, by ring⟩
