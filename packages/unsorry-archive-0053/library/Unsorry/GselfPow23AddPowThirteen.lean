import Mathlib

theorem gself_pow_23_add_pow_thirteen (n : ℤ) : (n) ∣ (n^23 + n^13) := by
  exact ⟨n^22 + n^12, by ring⟩
