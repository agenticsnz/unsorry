import Mathlib

theorem gself_pow_four_pow_twenty_add_pow_eighteen (n : ℤ) : (n^4) ∣ (n^20 + n^18) := by
  exact ⟨n^16 + n^14, by ring⟩
