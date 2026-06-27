import Mathlib

theorem gself_pow_two_pow_25_add_pow_sixteen (n : ℤ) : (n^2) ∣ (n^25 + n^16) := by
  exact ⟨n^23 + n^14, by ring⟩
