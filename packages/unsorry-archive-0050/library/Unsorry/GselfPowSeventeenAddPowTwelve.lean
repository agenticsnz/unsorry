import Mathlib

theorem gself_pow_seventeen_add_pow_twelve (n : ℤ) : (n) ∣ (n^17 + n^12) := by
  exact ⟨n^16 + n^11, by ring⟩
