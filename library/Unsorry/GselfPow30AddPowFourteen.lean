import Mathlib

theorem gself_pow_30_add_pow_fourteen (n : ℤ) : (n) ∣ (n^30 + n^14) := by
  exact ⟨n^29 + n^13, by ring⟩
