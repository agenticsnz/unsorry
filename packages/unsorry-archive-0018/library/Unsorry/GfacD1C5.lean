import Mathlib

theorem gfac_d1_c5 (n : ℤ) : (n - 1) ∣ (n^3 - n^2 - n + 1) := by
  exact ⟨n^2 - 1, by ring⟩
