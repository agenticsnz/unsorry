import Mathlib

theorem gself_pow_30_add_pow_21 (n : ℤ) : (n) ∣ (n^30 + n^21) := by
  exact ⟨n^29 + n^20, by ring⟩
