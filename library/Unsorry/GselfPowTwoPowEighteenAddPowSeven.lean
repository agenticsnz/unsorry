import Mathlib

theorem gself_pow_two_pow_eighteen_add_pow_seven (n : ℤ) : (n^2) ∣ (n^18 + n^7) := by
  exact ⟨n^16 + n^5, by ring⟩
