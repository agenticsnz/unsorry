import Mathlib

theorem gfac_d6_c3 (n : ℤ) : (2*n + 1) ∣ (2*n^3 + 3*n^2 + 3*n + 1) := by
  exact ⟨n^2 + n + 1, by ring⟩
