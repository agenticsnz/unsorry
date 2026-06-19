import Mathlib

theorem gself_pow_30_add_pow_sixteen (n : ℤ) : (n) ∣ (n^30 + n^16) := by
  exact ⟨n^29 + n^15, by ring⟩
