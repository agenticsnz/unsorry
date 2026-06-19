import Mathlib

theorem gself_pow_28_add_pow_seven (n : ℤ) : (n) ∣ (n^28 + n^7) := by
  exact ⟨n^27 + n^6, by ring⟩
