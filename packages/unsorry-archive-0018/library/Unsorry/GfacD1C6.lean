import Mathlib

theorem gfac_d1_c6 (n : ℤ) : (n - 1) ∣ (n^2 + n - 2) := by
  exact ⟨n + 2, by ring⟩
