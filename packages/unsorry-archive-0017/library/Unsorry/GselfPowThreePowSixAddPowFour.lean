import Mathlib

theorem gself_pow_three_pow_six_add_pow_four (n : ℤ) : (n^3) ∣ (n^6 + n^4) := by
  exact ⟨n^3 + n, by ring⟩
