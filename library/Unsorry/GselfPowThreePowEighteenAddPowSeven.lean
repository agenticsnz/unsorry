import Mathlib

theorem gself_pow_three_pow_eighteen_add_pow_seven (n : ℤ) : (n^3) ∣ (n^18 + n^7) := by
  exact ⟨n^15 + n^4, by ring⟩
