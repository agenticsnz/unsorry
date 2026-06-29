import Mathlib

theorem gself_pow_two_pow_26_add_pow_22 (n : ℤ) : (n^2) ∣ (n^26 + n^22) := by
  exact ⟨n^24 + n^20, by ring⟩
