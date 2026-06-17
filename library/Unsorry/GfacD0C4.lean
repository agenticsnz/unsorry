import Mathlib

theorem gfac_d0_c4 (n : ℤ) : (n) ∣ (n^3 - n^2 + n) := by
  exact ⟨n^2 - n + 1, by ring⟩
