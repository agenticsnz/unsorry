import Mathlib

theorem gself_pow_two_pow_eighteen_add_pow_ten (n : ℤ) : (n^2) ∣ (n^18 + n^10) := by
  exact ⟨n^16 + n^8, by ring⟩
