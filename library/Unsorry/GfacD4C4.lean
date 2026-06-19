import Mathlib

theorem gfac_d4_c4 (n : ℤ) : (n^2 + n + 1) ∣ (n^4 + n^2 + 1) := by
  exact ⟨n^2 - n + 1, by ring⟩
