import Mathlib

theorem gself_pow_two_pow_eighteen_add_pow_five (n : ℤ) : (n^2) ∣ (n^18 + n^5) := by
  exact ⟨n^16 + n^3, by ring⟩
