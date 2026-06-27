import Mathlib

theorem gself_pow_two_pow_29_add_pow_seven (n : ℤ) : (n^2) ∣ (n^29 + n^7) := by
  exact ⟨n^27 + n^5, by ring⟩
