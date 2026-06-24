import Mathlib

theorem gself_pow_two_pow_29_add_pow_twenty (n : ℤ) : (n^2) ∣ (n^29 + n^20) := by
  exact ⟨n^27 + n^18, by ring⟩
