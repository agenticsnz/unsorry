import Mathlib

theorem gself_pow_two_pow_22_add_pow_thirteen (n : ℤ) : (n^2) ∣ (n^22 + n^13) := by
  exact ⟨n^20 + n^11, by ring⟩
