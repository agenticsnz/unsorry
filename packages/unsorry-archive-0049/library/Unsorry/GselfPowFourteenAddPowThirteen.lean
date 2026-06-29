import Mathlib

theorem gself_pow_fourteen_add_pow_thirteen (n : ℤ) : (n) ∣ (n^14 + n^13) := by
  exact ⟨n^13 + n^12, by ring⟩
