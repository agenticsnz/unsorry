import Mathlib

theorem gself_pow_seventeen_add_pow_fifteen (n : ℤ) : (n) ∣ (n^17 + n^15) := by
  exact ⟨n^16 + n^14, by ring⟩
