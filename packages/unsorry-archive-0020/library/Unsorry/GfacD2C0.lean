import Mathlib

theorem gfac_d2_c0 (n : ℤ) : (n + 1) ∣ (n^2 + 2*n + 1) := by
  exact ⟨n + 1, by ring⟩
