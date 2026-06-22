import Mathlib

theorem gpow_diff_four_pow_thirteen (n : ℤ) : (n - 4) ∣ (n^13 - 67108864) := by
  exact ⟨n^12 + 4*n^11 + 16*n^10 + 64*n^9 + 256*n^8 + 1024*n^7 + 4096*n^6 + 16384*n^5 + 65536*n^4 + 262144*n^3 + 1048576*n^2 + 4194304*n + 16777216, by ring⟩
