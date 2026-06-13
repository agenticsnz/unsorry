import Mathlib.Tactic.Ring

theorem fourth_power_mod_three (n : ℕ) (h : n % 3 ≠ 0) : n ^ 4 % 3 = 1 := by
  obtain ⟨q, r, hr, rfl⟩ : ∃ q r, r < 3 ∧ n = 3 * q + r :=
    ⟨n / 3, n % 3, Nat.mod_lt _ (by omega), by omega⟩
  have hr' : r = 1 ∨ r = 2 := by omega
  rcases hr' with rfl | rfl
  · have e : (3 * q + 1) ^ 4 = 3 * (27 * q ^ 4 + 36 * q ^ 3 + 18 * q ^ 2 + 4 * q) + 1 := by ring
    rw [e]; omega
  · have e : (3 * q + 2) ^ 4 = 3 * (27 * q ^ 4 + 72 * q ^ 3 + 72 * q ^ 2 + 32 * q + 5) + 1 := by ring
    rw [e]; omega
