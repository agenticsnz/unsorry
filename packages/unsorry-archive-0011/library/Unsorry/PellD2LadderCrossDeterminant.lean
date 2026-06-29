import Mathlib.Tactic.LinearCombination

/-- For an integer solution of the Pell equation `x ^ 2 - 2 * y ^ 2 = 1`, the
cross determinant of the ladder step evaluates to `-2`. -/
theorem pell_d2_ladder_cross_determinant (x y : ℤ)
    (h : x ^ 2 - 2 * y ^ 2 = 1) :
    (3 * x + 4 * y) * y - x * (2 * x + 3 * y) = -2 := by
  linear_combination -2 * h
