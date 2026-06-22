import Mathlib

theorem gfac_d1_c1 (n : ℤ) : (n - 1) ∣ (n^2 - 2*n + 1) := by
  exact ⟨n - 1, by ring⟩
