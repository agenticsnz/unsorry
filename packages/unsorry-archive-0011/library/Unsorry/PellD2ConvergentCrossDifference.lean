import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith

/-- For the `d = 2` Pell recurrence, the cross difference of consecutive convergents
equals `-1`. With `pn = p + 2*q` and `qn = p + q`, and the Pell relation
`p^2 - 2*q^2 = 1`, we have `pn * q - p * qn = -1`. -/
theorem pell_d2_convergent_cross_difference (p q pn qn : ℤ)
    (hp : pn = p + 2 * q) (hq : qn = p + q) (h : p ^ 2 - 2 * q ^ 2 = 1) :
    pn * q - p * qn = -1 := by
  subst hp hq
  nlinarith [h]
