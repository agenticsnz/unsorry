import Mathlib

theorem gself_pow_two_pow_eighteen_add_pow_eight (n : ℤ) : (n^2) ∣ (n^18 + n^8) := by
  exact ⟨n^16 + n^6, by ring⟩
