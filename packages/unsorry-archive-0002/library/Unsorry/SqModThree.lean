import Mathlib.Tactic.Ring

theorem sq_mod_three (n : ℕ) (h : n % 3 ≠ 0) : n ^ 2 % 3 = 1 := by
  obtain ⟨q, r, hr, rfl⟩ : ∃ q r, r < 3 ∧ n = 3 * q + r :=
    ⟨n / 3, n % 3, Nat.mod_lt _ (by omega), by omega⟩
  have hr' : r = 1 ∨ r = 2 := by omega
  rcases hr' with rfl | rfl
  · have e : (3 * q + 1) ^ 2 = 3 * (3 * q * q + 2 * q) + 1 := by ring
    rw [e]; omega
  · have e : (3 * q + 2) ^ 2 = 3 * (3 * q * q + 4 * q + 1) + 1 := by ring
    rw [e]; omega
