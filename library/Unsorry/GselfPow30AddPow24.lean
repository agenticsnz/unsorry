import Mathlib

theorem gself_pow_30_add_pow_24 (n : ℤ) : (n) ∣ (n^30 + n^24) := by
  exact ⟨n^29 + n^23, by ring⟩
