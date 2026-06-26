import Mathlib

theorem gself_pow_29_add_pow_six (n : ℤ) : (n) ∣ (n^29 + n^6) := by
  exact ⟨n^28 + n^5, by ring⟩
