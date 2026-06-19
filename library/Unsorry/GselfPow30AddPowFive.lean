import Mathlib

theorem gself_pow_30_add_pow_five (n : ℤ) : (n) ∣ (n^30 + n^5) := by
  exact ⟨n^29 + n^4, by ring⟩
