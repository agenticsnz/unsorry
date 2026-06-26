import Mathlib

theorem gself_pow_two_pow_eighteen_add_pow_three (n : ℤ) : (n^2) ∣ (n^18 + n^3) := by
  exact ⟨n^16 + n, by ring⟩
