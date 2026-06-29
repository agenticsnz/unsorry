import Mathlib

theorem gself_pow_two_pow_twenty_add_pow_sixteen (n : ℤ) : (n^2) ∣ (n^20 + n^16) := by
  exact ⟨n^18 + n^14, by ring⟩
