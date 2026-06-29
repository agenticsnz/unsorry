import Mathlib

theorem gself_pow_nineteen_add_pow_six (n : ℤ) : (n) ∣ (n^19 + n^6) := by
  exact ⟨n^18 + n^5, by ring⟩
