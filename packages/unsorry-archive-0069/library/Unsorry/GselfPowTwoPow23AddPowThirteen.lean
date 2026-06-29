import Mathlib

theorem gself_pow_two_pow_23_add_pow_thirteen (n : ℤ) : (n^2) ∣ (n^23 + n^13) := by
  exact ⟨n^21 + n^11, by ring⟩
