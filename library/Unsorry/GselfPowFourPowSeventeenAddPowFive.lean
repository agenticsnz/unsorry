import Mathlib

theorem gself_pow_four_pow_seventeen_add_pow_five (n : ℤ) : (n^4) ∣ (n^17 + n^5) := by
  exact ⟨n^13 + n, by ring⟩
