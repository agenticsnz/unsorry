import Mathlib

theorem gself_pow_four_pow_sixteen_add_pow_six (n : ℤ) : (n^4) ∣ (n^16 + n^6) := by
  exact ⟨n^12 + n^2, by ring⟩
