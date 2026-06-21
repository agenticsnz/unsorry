import Mathlib

theorem gfac_d6_c0 (n : ℤ) : (2*n + 1) ∣ (2*n^2 + 3*n + 1) := by
  exact ⟨n + 1, by ring⟩
