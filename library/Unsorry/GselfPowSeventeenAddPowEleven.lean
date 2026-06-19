import Mathlib

theorem gself_pow_seventeen_add_pow_eleven (n : ℤ) : (n) ∣ (n^17 + n^11) := by
  exact ⟨n^16 + n^10, by ring⟩
