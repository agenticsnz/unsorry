import Mathlib

theorem gfac_d5_c5 (n : ℤ) : (n^2 - n + 1) ∣ (n^4 - n^3 + n - 1) := by
  exact ⟨n^2 - 1, by ring⟩
