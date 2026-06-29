import Mathlib

theorem gself_pow_28_add_pow_two (n : ℤ) : (n) ∣ (n^28 + n^2) := by
  exact ⟨n^27 + n, by ring⟩
