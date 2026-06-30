import Mathlib

theorem gself_pow_three_pow_seventeen_add_pow_eight (n : ℤ) : (n^3) ∣ (n^17 + n^8) := by
  exact ⟨n^14 + n^5, by ring⟩
