import Mathlib

theorem gself_pow_seventeen_add_pow_four (n : ℤ) : (n) ∣ (n^17 + n^4) := by
  exact ⟨n^16 + n^3, by ring⟩
