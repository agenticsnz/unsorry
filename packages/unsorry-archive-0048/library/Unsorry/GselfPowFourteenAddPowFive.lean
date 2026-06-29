import Mathlib

theorem gself_pow_fourteen_add_pow_five (n : ℤ) : (n) ∣ (n^14 + n^5) := by
  exact ⟨n^13 + n^4, by ring⟩
