import Mathlib

theorem gself_pow_four_pow_22_add_pow_five (n : ℤ) : (n^4) ∣ (n^22 + n^5) := by
  exact ⟨n^18 + n, by ring⟩
