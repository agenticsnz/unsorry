import Mathlib

theorem gself_pow_fourteen_add_pow_twelve (n : ℤ) : (n) ∣ (n^14 + n^12) := by
  exact ⟨n^13 + n^11, by ring⟩
