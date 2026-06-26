import Mathlib

theorem gself_pow_three_pow_29_add_pow_thirteen (n : ℤ) : (n^3) ∣ (n^29 + n^13) := by
  exact ⟨n^26 + n^10, by ring⟩
