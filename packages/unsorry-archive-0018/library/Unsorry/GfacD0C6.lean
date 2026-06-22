import Mathlib

theorem gfac_d0_c6 (n : ℤ) : (n) ∣ (n^2 + 2*n) := by
  exact ⟨n + 2, by ring⟩
