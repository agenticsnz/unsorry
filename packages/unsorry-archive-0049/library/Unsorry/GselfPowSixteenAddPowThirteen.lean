import Mathlib

theorem gself_pow_sixteen_add_pow_thirteen (n : ℤ) : (n) ∣ (n^16 + n^13) := by
  exact ⟨n^15 + n^12, by ring⟩
