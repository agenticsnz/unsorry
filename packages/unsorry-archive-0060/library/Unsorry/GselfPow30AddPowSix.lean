import Mathlib

theorem gself_pow_30_add_pow_six (n : ℤ) : (n) ∣ (n^30 + n^6) := by
  exact ⟨n^29 + n^5, by ring⟩
