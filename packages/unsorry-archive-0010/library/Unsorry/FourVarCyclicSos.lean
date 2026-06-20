import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Linarith

theorem four_var_cyclic_sos (a b c d : ℝ) : a * b + b * c + c * d + d * a ≤ a ^ 2 + b ^ 2 + c ^ 2 + d ^ 2 := by
  have h1 : 0 ≤ (a - b) ^ 2 := sq_nonneg (a - b)
  have h2 : 0 ≤ (b - c) ^ 2 := sq_nonneg (b - c)
  have h3 : 0 ≤ (c - d) ^ 2 := sq_nonneg (c - d)
  have h4 : 0 ≤ (d - a) ^ 2 := sq_nonneg (d - a)
  linarith
