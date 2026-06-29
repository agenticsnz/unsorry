import Mathlib

theorem gself_pow_two_pow_24_add_pow_twenty (n : ℤ) : (n^2) ∣ (n^24 + n^20) := by
  exact ⟨n^22 + n^18, by ring⟩
