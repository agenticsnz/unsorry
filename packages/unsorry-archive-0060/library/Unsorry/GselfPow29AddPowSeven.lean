import Mathlib

theorem gself_pow_29_add_pow_seven (n : ℤ) : (n) ∣ (n^29 + n^7) := by
  exact ⟨n^28 + n^6, by ring⟩
