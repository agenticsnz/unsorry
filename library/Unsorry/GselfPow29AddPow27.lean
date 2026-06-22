import Mathlib

theorem gself_pow_29_add_pow_27 (n : ℤ) : (n) ∣ (n^29 + n^27) := by
  exact ⟨n^28 + n^26, by ring⟩
