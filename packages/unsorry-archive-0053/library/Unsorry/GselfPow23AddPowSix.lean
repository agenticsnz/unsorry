import Mathlib

theorem gself_pow_23_add_pow_six (n : ℤ) : (n) ∣ (n^23 + n^6) := by
  exact ⟨n^22 + n^5, by ring⟩
