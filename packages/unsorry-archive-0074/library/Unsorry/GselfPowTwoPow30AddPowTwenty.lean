import Mathlib

theorem gself_pow_two_pow_30_add_pow_twenty (n : ℤ) : (n^2) ∣ (n^30 + n^20) := by
  exact ⟨n^28 + n^18, by ring⟩
