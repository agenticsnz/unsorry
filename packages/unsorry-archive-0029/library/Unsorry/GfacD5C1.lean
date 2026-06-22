import Mathlib

theorem gfac_d5_c1 (n : ℤ) : (n^2 - n + 1) ∣ (n^3 - 2*n^2 + 2*n - 1) := by
  exact ⟨n - 1, by ring⟩
