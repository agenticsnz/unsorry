import Mathlib

theorem gself_pow_30_add_pow_eight (n : ℤ) : (n) ∣ (n^30 + n^8) := by
  exact ⟨n^29 + n^7, by ring⟩
