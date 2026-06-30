import Mathlib

theorem gself_pow_three_pow_eighteen_add_pow_eleven (n : ℤ) : (n^3) ∣ (n^18 + n^11) := by
  exact ⟨n^15 + n^8, by ring⟩
