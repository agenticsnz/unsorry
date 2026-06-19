import Mathlib

theorem gself_pow_six_add_pow_one (n : ℤ) : (n) ∣ (n^6 + n) := by
  exact ⟨n^5 + 1, by ring⟩
