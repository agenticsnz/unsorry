import Mathlib

theorem gself_pow_two_pow_24_add_pow_sixteen (n : ℤ) : (n^2) ∣ (n^24 + n^16) := by
  exact ⟨n^22 + n^14, by ring⟩
