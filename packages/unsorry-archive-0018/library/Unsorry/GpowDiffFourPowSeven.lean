import Mathlib

theorem gpow_diff_four_pow_seven (n : ℤ) : (n - 4) ∣ (n^7 - 16384) := by
  exact ⟨n^6 + 4*n^5 + 16*n^4 + 64*n^3 + 256*n^2 + 1024*n + 4096, by ring⟩
