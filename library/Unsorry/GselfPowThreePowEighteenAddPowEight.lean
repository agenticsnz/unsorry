import Mathlib

theorem gself_pow_three_pow_eighteen_add_pow_eight (n : ℤ) : (n^3) ∣ (n^18 + n^8) := by
  exact ⟨n^15 + n^5, by ring⟩
