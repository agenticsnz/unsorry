import Mathlib

theorem gpow_diff_eight_pow_thirteen (n : ℤ) : (n - 8) ∣ (n^13 - 549755813888) := by
  exact ⟨n^12 + 8*n^11 + 64*n^10 + 512*n^9 + 4096*n^8 + 32768*n^7 + 262144*n^6 + 2097152*n^5 + 16777216*n^4 + 134217728*n^3 + 1073741824*n^2 + 8589934592*n + 68719476736, by ring⟩
