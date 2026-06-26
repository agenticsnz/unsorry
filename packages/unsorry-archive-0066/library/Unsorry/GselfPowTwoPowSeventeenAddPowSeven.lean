import Mathlib

theorem gself_pow_two_pow_seventeen_add_pow_seven (n : ℤ) : (n^2) ∣ (n^17 + n^7) := by
  exact ⟨n^15 + n^5, by ring⟩
