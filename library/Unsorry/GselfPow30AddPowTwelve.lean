import Mathlib

theorem gself_pow_30_add_pow_twelve (n : ℤ) : (n) ∣ (n^30 + n^12) := by
  exact ⟨n^29 + n^11, by ring⟩
