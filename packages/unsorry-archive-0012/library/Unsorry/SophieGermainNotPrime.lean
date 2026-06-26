import Mathlib.Algebra.Prime.Defs
import Mathlib.Algebra.Group.Int.Units
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring

theorem sophie_germain_not_prime (a b : ℤ) (ha : 2 ≤ a) (hb : 1 ≤ b) : ¬ Prime (a ^ 4 + 4 * b ^ 4) := by
  intro hp
  let x : ℤ := a ^ 2 - 2 * a * b + 2 * b ^ 2
  let y : ℤ := a ^ 2 + 2 * a * b + 2 * b ^ 2
  have hfac : a ^ 4 + 4 * b ^ 4 = x * y := by
    dsimp [x, y]
    ring
  have hx2 : 2 ≤ x := by
    dsimp [x]
    nlinarith [sq_nonneg (a - b), sq_nonneg (b - 1), ha, hb]
  have hy2 : 2 ≤ y := by
    dsimp [y]
    nlinarith [sq_nonneg a, sq_nonneg b, mul_nonneg (show 0 ≤ a by linarith) (show 0 ≤ b by linarith)]
  have hxu : ¬ IsUnit x := by
    intro h
    rcases Int.isUnit_eq_one_or h with hx | hx <;> linarith
  have hyu : ¬ IsUnit y := by
    intro h
    rcases Int.isUnit_eq_one_or h with hy | hy <;> linarith
  have hprod_prime : Prime (x * y) := by
    rwa [← hfac]
  exact (hprod_prime.irreducible.isUnit_or_isUnit rfl).elim hxu hyu
