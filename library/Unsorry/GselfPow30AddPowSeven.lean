import Mathlib

theorem gself_pow_30_add_pow_seven (n : ℤ) : (n) ∣ (n^30 + n^7) := by
  exact ⟨n^29 + n^6, by ring⟩
