import Mathlib

theorem gself_pow_26_add_pow_eighteen (n : ℤ) : (n) ∣ (n^26 + n^18) := by
  exact ⟨n^25 + n^17, by ring⟩
