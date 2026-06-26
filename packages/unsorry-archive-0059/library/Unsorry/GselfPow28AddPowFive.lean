import Mathlib

theorem gself_pow_28_add_pow_five (n : ℤ) : (n) ∣ (n^28 + n^5) := by
  exact ⟨n^27 + n^4, by ring⟩
