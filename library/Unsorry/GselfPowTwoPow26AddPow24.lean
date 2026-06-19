import Mathlib

theorem gself_pow_two_pow_26_add_pow_24 (n : ℤ) : (n^2) ∣ (n^26 + n^24) := by
  exact ⟨n^24 + n^22, by ring⟩
