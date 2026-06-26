import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Ring.Abs
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity

/-- For `a, b ∈ [0, 1]`, the square of `a - b` is at most `|a - b|`.

The difference `a - b` lies in `[-1, 1]`, so its absolute value `t := |a - b|`
satisfies `0 ≤ t ≤ 1`. Then `(a - b) ^ 2 = t ^ 2 = t * t ≤ t * 1 = t`. -/
theorem sq_sub_le_abs_sub (a b : ℝ) (ha : a ∈ Set.Icc (0:ℝ) 1)
    (hb : b ∈ Set.Icc (0:ℝ) 1) : (a - b) ^ 2 ≤ |a - b| := by
  obtain ⟨ha0, ha1⟩ := ha
  obtain ⟨hb0, hb1⟩ := hb
  have hsq : (a - b) ^ 2 = |a - b| ^ 2 := (sq_abs _).symm
  rw [hsq]
  have hle : |a - b| ≤ 1 := abs_le.mpr ⟨by linarith, by linarith⟩
  have hnn : 0 ≤ |a - b| := abs_nonneg _
  nlinarith [mul_nonneg hnn (by linarith : (0:ℝ) ≤ 1 - |a - b|)]
