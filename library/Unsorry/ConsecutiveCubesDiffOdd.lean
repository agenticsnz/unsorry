import Mathlib

theorem consecutive_cubes_diff_odd (n : ℤ) : Odd ((n + 1) ^ 3 - n ^ 3) := by
  rcases Int.even_or_odd n with ⟨k, rfl⟩ | ⟨k, rfl⟩
  · exact ⟨6 * k ^ 2 + 3 * k, by ring⟩
  · exact ⟨6 * k ^ 2 + 9 * k + 3, by ring⟩
