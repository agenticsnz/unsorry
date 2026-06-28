import Mathlib

theorem gself_pow_four_pow_five_add_pow_four (n : ℤ) : (n^4) ∣ (n^5 + n^4) := by
  exact ⟨n + 1, by ring⟩
