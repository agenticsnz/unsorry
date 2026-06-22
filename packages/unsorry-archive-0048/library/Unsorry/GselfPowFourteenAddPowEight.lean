import Mathlib

theorem gself_pow_fourteen_add_pow_eight (n : ℤ) : (n) ∣ (n^14 + n^8) := by
  exact ⟨n^13 + n^7, by ring⟩
