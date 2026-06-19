import Mathlib

theorem gself_pow_28_add_pow_21 (n : ℤ) : (n) ∣ (n^28 + n^21) := by
  exact ⟨n^27 + n^20, by ring⟩
