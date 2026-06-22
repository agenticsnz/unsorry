import Mathlib

theorem gself_pow_sixteen_add_pow_six (n : ℤ) : (n) ∣ (n^16 + n^6) := by
  exact ⟨n^15 + n^5, by ring⟩
