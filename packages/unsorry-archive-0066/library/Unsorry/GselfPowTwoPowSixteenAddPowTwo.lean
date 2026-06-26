import Mathlib

theorem gself_pow_two_pow_sixteen_add_pow_two (n : ℤ) : (n^2) ∣ (n^16 + n^2) := by
  exact ⟨n^14 + 1, by ring⟩
