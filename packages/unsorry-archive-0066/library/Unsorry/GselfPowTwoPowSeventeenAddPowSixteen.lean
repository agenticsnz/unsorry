import Mathlib

theorem gself_pow_two_pow_seventeen_add_pow_sixteen (n : ℤ) : (n^2) ∣ (n^17 + n^16) := by
  exact ⟨n^15 + n^14, by ring⟩
