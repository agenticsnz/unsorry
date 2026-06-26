import Mathlib

theorem gself_pow_seventeen_add_pow_five (n : ℤ) : (n) ∣ (n^17 + n^5) := by
  exact ⟨n^16 + n^4, by ring⟩
