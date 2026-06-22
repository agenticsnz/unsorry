import Mathlib

theorem gfac_d4_c1 (n : ℤ) : (n^2 + n + 1) ∣ (n^3 - 1) := by
  exact ⟨n - 1, by ring⟩
