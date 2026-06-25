import Mathlib

theorem gself_pow_28_add_pow_eighteen (n : ℤ) : (n) ∣ (n^28 + n^18) := by
  exact ⟨n^27 + n^17, by ring⟩
