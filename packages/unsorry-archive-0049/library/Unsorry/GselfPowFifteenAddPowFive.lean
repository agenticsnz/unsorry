import Mathlib

theorem gself_pow_fifteen_add_pow_five (n : ℤ) : (n) ∣ (n^15 + n^5) := by
  exact ⟨n^14 + n^4, by ring⟩
