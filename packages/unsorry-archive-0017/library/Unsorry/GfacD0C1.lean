import Mathlib

theorem gfac_d0_c1 (n : ℤ) : (n) ∣ (n^2 - n) := by
  exact ⟨n - 1, by ring⟩
