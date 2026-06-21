import Mathlib.Tactic.Ring

theorem square_eq_two_mul_square_halves (a b c d : ℕ) (ha : a = 2 * c) (hb : b = 2 * d)
    (h : a ^ 2 = 2 * b ^ 2) : c ^ 2 = 2 * d ^ 2 := by
  subst a
  subst b
  have h4 : 4 * c ^ 2 = 4 * (2 * d ^ 2) := by
    calc
      4 * c ^ 2 = (2 * c) ^ 2 := by ring
      _ = 2 * (2 * d) ^ 2 := h
      _ = 4 * (2 * d ^ 2) := by ring
  exact mul_left_cancel₀ (by decide : (4 : ℕ) ≠ 0) h4
