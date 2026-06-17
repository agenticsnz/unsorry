import Mathlib

theorem gfac_d0_c5 (n : ℤ) : (n) ∣ (n^3 - n) := by
  exact ⟨n^2 - 1, by ring⟩
