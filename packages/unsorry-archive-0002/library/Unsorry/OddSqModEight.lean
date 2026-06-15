import Mathlib.Algebra.Group.Nat.Even
import Mathlib.Tactic.Ring

theorem odd_sq_mod_eight (n : ℕ) (h : Odd n) : n ^ 2 % 8 = 1 := by
  obtain ⟨k, rfl⟩ := h
  obtain ⟨m, hm⟩ : Even (k * (k + 1)) := Nat.even_mul_succ_self k
  have hsq : (2 * k + 1) ^ 2 = 4 * (k * (k + 1)) + 1 := by ring
  rw [hsq, hm]
  omega
