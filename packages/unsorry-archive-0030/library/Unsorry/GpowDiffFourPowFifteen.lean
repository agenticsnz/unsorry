import Mathlib

theorem gpow_diff_four_pow_fifteen (n : ℤ) : (n - 4) ∣ (n^15 - 1073741824) := by
  exact ⟨n^14 + 4*n^13 + 16*n^12 + 64*n^11 + 256*n^10 + 1024*n^9 + 4096*n^8 + 16384*n^7 + 65536*n^6 + 262144*n^5 + 1048576*n^4 + 4194304*n^3 + 16777216*n^2 + 67108864*n + 268435456, by ring⟩
