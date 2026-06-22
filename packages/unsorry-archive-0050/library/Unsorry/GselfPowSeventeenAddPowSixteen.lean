import Mathlib

theorem gself_pow_seventeen_add_pow_sixteen (n : ℤ) : (n) ∣ (n^17 + n^16) := by
  exact ⟨n^16 + n^15, by ring⟩
