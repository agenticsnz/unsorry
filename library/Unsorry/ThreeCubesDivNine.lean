import Mathlib.Tactic.Ring

theorem three_cubes_div_nine (n : ℕ) : 9 ∣ n ^ 3 + (n + 1) ^ 3 + (n + 2) ^ 3 := by
  obtain ⟨q, r, hr, rfl⟩ : ∃ q r, r < 3 ∧ n = 3 * q + r :=
    ⟨n / 3, n % 3, Nat.mod_lt _ (by omega), by omega⟩
  have hr' : r = 0 ∨ r = 1 ∨ r = 2 := by omega
  rcases hr' with rfl | rfl | rfl
  · exact ⟨9 * q ^ 3 + 9 * q ^ 2 + 5 * q + 1, by ring⟩
  · exact ⟨9 * q ^ 3 + 18 * q ^ 2 + 14 * q + 4, by ring⟩
  · exact ⟨9 * q ^ 3 + 27 * q ^ 2 + 29 * q + 11, by ring⟩
