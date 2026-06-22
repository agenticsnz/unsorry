import Mathlib

theorem gself_pow_seventeen_add_pow_six (n : ℤ) : (n) ∣ (n^17 + n^6) := by
  exact ⟨n^16 + n^5, by ring⟩
