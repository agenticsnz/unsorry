import Mathlib

theorem gself_pow_two_pow_fourteen_add_pow_eight (n : ℤ) : (n^2) ∣ (n^14 + n^8) := by
  exact ⟨n^12 + n^6, by ring⟩
