import Mathlib

theorem gself_pow_seventeen_add_pow_ten (n : ℤ) : (n) ∣ (n^17 + n^10) := by
  exact ⟨n^16 + n^9, by ring⟩
