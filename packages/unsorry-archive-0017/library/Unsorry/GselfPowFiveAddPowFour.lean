import Mathlib

theorem gself_pow_five_add_pow_four (n : ℤ) : (n) ∣ (n^5 + n^4) := by
  exact ⟨n^4 + n^3, by ring⟩
