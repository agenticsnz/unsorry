import Mathlib

theorem gself_pow_six_add_pow_five (n : ℤ) : (n) ∣ (n^6 + n^5) := by
  exact ⟨n^5 + n^4, by ring⟩
