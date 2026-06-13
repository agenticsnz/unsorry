import Mathlib.Algebra.Group.Nat.Even
import Mathlib.Tactic.Ring

theorem odd_fourth_power_mod_sixteen (n : ℕ) (h : Odd n) : n ^ 4 % 16 = 1 := by
  obtain ⟨k, rfl⟩ := h
  obtain ⟨j, s, hs, rfl⟩ : ∃ j s, s < 4 ∧ k = 4 * j + s :=
    ⟨k / 4, k % 4, by omega, by omega⟩
  have hs' : s = 0 ∨ s = 1 ∨ s = 2 ∨ s = 3 := by omega
  rcases hs' with rfl | rfl | rfl | rfl
  · have e : (2 * (4 * j + 0) + 1) ^ 4
        = 16 * (256 * j ^ 4 + 128 * j ^ 3 + 24 * j ^ 2 + 2 * j) + 1 := by ring
    rw [e]; omega
  · have e : (2 * (4 * j + 1) + 1) ^ 4
        = 16 * (256 * j ^ 4 + 384 * j ^ 3 + 216 * j ^ 2 + 54 * j + 5) + 1 := by ring
    rw [e]; omega
  · have e : (2 * (4 * j + 2) + 1) ^ 4
        = 16 * (256 * j ^ 4 + 640 * j ^ 3 + 600 * j ^ 2 + 250 * j + 39) + 1 := by ring
    rw [e]; omega
  · have e : (2 * (4 * j + 3) + 1) ^ 4
        = 16 * (256 * j ^ 4 + 896 * j ^ 3 + 1176 * j ^ 2 + 686 * j + 150) + 1 := by ring
    rw [e]; omega
