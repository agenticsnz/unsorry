import Mathlib

theorem gself_pow_two_pow_sixteen_add_pow_twelve (n : ℤ) : (n^2) ∣ (n^16 + n^12) := by
  exact ⟨n^14 + n^10, by ring⟩
