import Mathlib

theorem gself_pow_four_pow_six_add_pow_four (n : ℤ) : (n^4) ∣ (n^6 + n^4) := by
  exact ⟨n^2 + 1, by ring⟩
