import Mathlib

theorem gself_pow_two_pow_six_add_pow_four (n : ℤ) : (n^2) ∣ (n^6 + n^4) := by
  exact ⟨n^4 + n^2, by ring⟩
