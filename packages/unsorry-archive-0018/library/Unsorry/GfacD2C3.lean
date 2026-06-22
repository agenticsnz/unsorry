import Mathlib

theorem gfac_d2_c3 (n : ℤ) : (n + 1) ∣ (n^3 + 2*n^2 + 2*n + 1) := by
  exact ⟨n^2 + n + 1, by ring⟩
