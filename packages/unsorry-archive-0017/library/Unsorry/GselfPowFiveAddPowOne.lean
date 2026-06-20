import Mathlib

theorem gself_pow_five_add_pow_one (n : ℤ) : (n) ∣ (n^5 + n) := by
  exact ⟨n^4 + 1, by ring⟩
