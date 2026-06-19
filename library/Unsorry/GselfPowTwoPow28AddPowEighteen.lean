import Mathlib

theorem gself_pow_two_pow_28_add_pow_eighteen (n : ℤ) : (n^2) ∣ (n^28 + n^18) := by
  exact ⟨n^26 + n^16, by ring⟩
