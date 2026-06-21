import Mathlib

theorem gpow_diff_seven_pow_five (n : ℤ) : (n - 7) ∣ (n^5 - 16807) := by
  exact ⟨n^4 + 7*n^3 + 49*n^2 + 343*n + 2401, by ring⟩
