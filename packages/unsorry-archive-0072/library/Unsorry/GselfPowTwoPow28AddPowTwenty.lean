import Mathlib

theorem gself_pow_two_pow_28_add_pow_twenty (n : ℤ) : (n^2) ∣ (n^28 + n^20) := by
  exact ⟨n^26 + n^18, by ring⟩
