import Mathlib

theorem gself_pow_two_add_pow_one (n : ℤ) : (n) ∣ (n^2 + n) := by
  exact ⟨n + 1, by ring⟩
