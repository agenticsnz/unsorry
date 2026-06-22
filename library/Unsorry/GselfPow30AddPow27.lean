import Mathlib

theorem gself_pow_30_add_pow_27 (n : ℤ) : (n) ∣ (n^30 + n^27) := by
  exact ⟨n^29 + n^26, by ring⟩
