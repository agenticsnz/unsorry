import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.Real.Sqrt
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.LinearCombination

/-!
AIME 1990 Problem 2: `(52 + 6√43) ^ (3/2) - (52 - 6√43) ^ (3/2) = 828`.

Since `(√43 + 3) ^ 2 = 52 + 6√43` and `(√43 - 3) ^ 2 = 52 - 6√43`, and both
bases are nonnegative (`√43 ≥ 3` because `43 ≥ 9`), each real-exponent power
of a square collapses to a cube: `(x ^ 2) ^ (3/2) = x ^ 3` for `0 ≤ x`.
The difference of cubes then expands to
`18 * (√43) ^ 2 + 54 = 18 * 43 + 54 = 828`.
-/

theorem aime_1990_p2 :
    (52 + 6 * Real.sqrt 43) ^ ((3 : ℝ) / 2) - (52 - 6 * Real.sqrt 43) ^ ((3 : ℝ) / 2) = 828 := by
  have hs0 : (0 : ℝ) ≤ Real.sqrt 43 := Real.sqrt_nonneg 43
  have hs2 : Real.sqrt 43 ^ 2 = 43 := Real.sq_sqrt (by norm_num)
  have h3s : (3 : ℝ) ≤ Real.sqrt 43 := by nlinarith [hs0, hs2]
  -- For a nonnegative base, the `3 / 2` real power of a square is a cube.
  have key : ∀ x : ℝ, 0 ≤ x → (x ^ 2) ^ ((3 : ℝ) / 2) = x ^ 3 := by
    intro x hx
    rw [← Real.rpow_natCast x 2, ← Real.rpow_mul hx, ← Real.rpow_natCast x 3]
    norm_num
  have ha : (52 : ℝ) + 6 * Real.sqrt 43 = (Real.sqrt 43 + 3) ^ 2 := by
    linear_combination -hs2
  have hb : (52 : ℝ) - 6 * Real.sqrt 43 = (Real.sqrt 43 - 3) ^ 2 := by
    linear_combination -hs2
  rw [ha, hb, key (Real.sqrt 43 + 3) (by linarith), key (Real.sqrt 43 - 3) (by linarith)]
  linear_combination 18 * hs2
