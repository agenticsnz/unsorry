import Mathlib

theorem gself_pow_two_pow_thirteen_add_pow_eight (n : ℤ) : (n^2) ∣ (n^13 + n^8) := by
  exact ⟨n^11 + n^6, by ring⟩
