import Mathlib

theorem gpow_diff_seven_pow_ten (n : ℤ) : (n - 7) ∣ (n^10 - 282475249) := by
  exact ⟨n^9 + 7*n^8 + 49*n^7 + 343*n^6 + 2401*n^5 + 16807*n^4 + 117649*n^3 + 823543*n^2 + 5764801*n + 40353607, by ring⟩
