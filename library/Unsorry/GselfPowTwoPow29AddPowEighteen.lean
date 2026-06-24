import Mathlib

theorem gself_pow_two_pow_29_add_pow_eighteen (n : ℤ) : (n^2) ∣ (n^29 + n^18) := by
  exact ⟨n^27 + n^16, by ring⟩
