import Mathlib

theorem gpow_diff_four_pow_ten (n : ℤ) : (n - 4) ∣ (n^10 - 1048576) := by
  exact ⟨n^9 + 4*n^8 + 16*n^7 + 64*n^6 + 256*n^5 + 1024*n^4 + 4096*n^3 + 16384*n^2 + 65536*n + 262144, by ring⟩
