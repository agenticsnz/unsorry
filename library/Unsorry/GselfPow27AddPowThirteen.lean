import Mathlib

theorem gself_pow_27_add_pow_thirteen (n : ℤ) : (n) ∣ (n^27 + n^13) := by
  exact ⟨n^26 + n^12, by ring⟩
