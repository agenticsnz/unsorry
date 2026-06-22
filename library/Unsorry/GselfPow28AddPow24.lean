import Mathlib

theorem gself_pow_28_add_pow_24 (n : ℤ) : (n) ∣ (n^28 + n^24) := by
  exact ⟨n^27 + n^23, by ring⟩
