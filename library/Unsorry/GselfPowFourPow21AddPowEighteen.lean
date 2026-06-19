import Mathlib

theorem gself_pow_four_pow_21_add_pow_eighteen (n : ℤ) : (n^4) ∣ (n^21 + n^18) := by
  exact ⟨n^17 + n^14, by ring⟩
