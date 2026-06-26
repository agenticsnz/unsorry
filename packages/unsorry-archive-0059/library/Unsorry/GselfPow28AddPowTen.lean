import Mathlib

theorem gself_pow_28_add_pow_ten (n : ℤ) : (n) ∣ (n^28 + n^10) := by
  exact ⟨n^27 + n^9, by ring⟩
