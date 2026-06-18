import Unsorry.AmGmThreeCubeS2S1
import Unsorry.AmGmThreeCubeS2S2

/-- Weighted AM-GM in the form `27 * (x^2 * y) ≤ 4 * (x + y)^3` for nonnegative
reals. The gap factors as a perfect square times a nonnegative linear term, so
the inequality follows from the two proved factor lemmas by linear arithmetic. -/
theorem weighted_am_gm_two_one_cube (x y : ℝ) (hx : 0 ≤ x) (hy : 0 ≤ y) :
    27 * (x ^ 2 * y) ≤ 4 * (x + y) ^ 3 := by
  have h1 := weighted_am_gm_two_one_cube_factor_identity x y
  have h2 := weighted_am_gm_two_one_cube_factor_nonneg x y hx hy
  linarith
