import Mathlib

theorem gself_pow_two_pow_sixteen_add_pow_four (n : ℤ) : (n^2) ∣ (n^16 + n^4) := by
  exact ⟨n^14 + n^2, by ring⟩
