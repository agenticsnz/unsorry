import Mathlib

theorem gself_pow_two_pow_eighteen_add_pow_twelve (n : ℤ) : (n^2) ∣ (n^18 + n^12) := by
  exact ⟨n^16 + n^10, by ring⟩
