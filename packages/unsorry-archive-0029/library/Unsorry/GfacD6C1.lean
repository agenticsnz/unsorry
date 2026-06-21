import Mathlib

theorem gfac_d6_c1 (n : ℤ) : (2*n + 1) ∣ (2*n^2 - n - 1) := by
  exact ⟨n - 1, by ring⟩
