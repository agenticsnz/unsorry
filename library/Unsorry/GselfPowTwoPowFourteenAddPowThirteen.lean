import Mathlib

theorem gself_pow_two_pow_fourteen_add_pow_thirteen (n : ℤ) : (n^2) ∣ (n^14 + n^13) := by
  exact ⟨n^12 + n^11, by ring⟩
