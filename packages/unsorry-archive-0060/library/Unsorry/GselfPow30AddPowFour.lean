import Mathlib

theorem gself_pow_30_add_pow_four (n : ℤ) : (n) ∣ (n^30 + n^4) := by
  exact ⟨n^29 + n^3, by ring⟩
