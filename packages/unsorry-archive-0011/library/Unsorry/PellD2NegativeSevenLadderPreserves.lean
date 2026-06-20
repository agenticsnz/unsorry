import Mathlib

-- This module proves that the ladder transformation preserves solutions to the Pell equation with d = 2 and n = -7.

theorem pell_d2_negative_seven_ladder_preserves (x y : ℤ) (h : x ^ 2 - 2 * y ^ 2 = -7) : (3 * x + 4 * y) ^ 2 - 2 * (2 * x + 3 * y) ^ 2 = -7 := by
  ring_nf
  linarith