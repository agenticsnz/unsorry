import Mathlib

theorem gself_pow_four_pow_six_add_pow_five (n : ℤ) : (n^4) ∣ (n^6 + n^5) := by
  exact ⟨n^2 + n, by ring⟩
