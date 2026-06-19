import Mathlib

theorem gself_pow_three_pow_eighteen_add_pow_four (n : ℤ) : (n^3) ∣ (n^18 + n^4) := by
  exact ⟨n^15 + n, by ring⟩
