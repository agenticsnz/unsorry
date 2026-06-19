import Mathlib

theorem gself_pow_two_pow_five_add_pow_four (n : ℤ) : (n^2) ∣ (n^5 + n^4) := by
  exact ⟨n^3 + n^2, by ring⟩
