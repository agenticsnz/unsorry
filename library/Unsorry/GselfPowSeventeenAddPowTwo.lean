import Mathlib

theorem gself_pow_seventeen_add_pow_two (n : ℤ) : (n) ∣ (n^17 + n^2) := by
  exact ⟨n^16 + n, by ring⟩
