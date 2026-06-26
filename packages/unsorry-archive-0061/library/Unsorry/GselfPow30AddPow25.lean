import Mathlib

theorem gself_pow_30_add_pow_25 (n : ℤ) : (n) ∣ (n^30 + n^25) := by
  exact ⟨n^29 + n^24, by ring⟩
