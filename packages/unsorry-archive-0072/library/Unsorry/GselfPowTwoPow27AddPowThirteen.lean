import Mathlib

theorem gself_pow_two_pow_27_add_pow_thirteen (n : ℤ) : (n^2) ∣ (n^27 + n^13) := by
  exact ⟨n^25 + n^11, by ring⟩
