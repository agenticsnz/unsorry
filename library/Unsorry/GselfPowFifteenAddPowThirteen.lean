import Mathlib

theorem gself_pow_fifteen_add_pow_thirteen (n : ℤ) : (n) ∣ (n^15 + n^13) := by
  exact ⟨n^14 + n^12, by ring⟩
