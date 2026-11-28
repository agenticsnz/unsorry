import Mathlib.Data.Real.Sqrt
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring

/-- Putnam 1966 A6: for `x ≥ 0`, `√(1 + (x + 1)(x + 3)) = x + 2`. -/
theorem putnam_1966_a6_sqrt_identity (x : ℝ) (hx : 0 ≤ x) :
    Real.sqrt (1 + (x + 1) * (x + 3)) = x + 2 := by
  have h : 1 + (x + 1) * (x + 3) = (x + 2) ^ 2 := by ring
  rw [h, Real.sqrt_sq (show (0 : ℝ) ≤ x + 2 by linarith)]
