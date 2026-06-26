import Mathlib

theorem gself_pow_30_add_pow_fifteen (n : ℤ) : (n) ∣ (n^30 + n^15) := by
  exact ⟨n^29 + n^14, by ring⟩
