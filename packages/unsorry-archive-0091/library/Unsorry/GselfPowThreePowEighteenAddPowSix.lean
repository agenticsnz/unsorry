import Mathlib

theorem gself_pow_three_pow_eighteen_add_pow_six (n : ℤ) : (n^3) ∣ (n^18 + n^6) := by
  exact ⟨n^15 + n^3, by ring⟩
