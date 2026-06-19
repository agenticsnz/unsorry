import Mathlib

theorem gself_pow_two_pow_sixteen_add_pow_five (n : ℤ) : (n^2) ∣ (n^16 + n^5) := by
  exact ⟨n^14 + n^3, by ring⟩
