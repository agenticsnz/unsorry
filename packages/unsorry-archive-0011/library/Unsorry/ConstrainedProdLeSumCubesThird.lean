import Mathlib.Tactic

/-!
# Product bound for a unit-sum triple

For nonnegative reals `a`, `b`, `c` whose sum is `1`, the product `a * b * c`
is at most `1 / 27`. This is the three-variable arithmetic/geometric mean
inequality specialised to the unit simplex: the maximum of the product on the
plane `a + b + c = 1` is attained at the centroid `a = b = c = 1 / 3`.

The polynomial certificate behind the proof is the weighted sum of squares
`a * (b - c) ^ 2 + b * (a - c) ^ 2 + c * (a - b) ^ 2 ≥ 0` together with the
nonnegativity of the coordinates, which `nlinarith` combines after eliminating
the constraint `a + b + c = 1`.
-/

theorem constrained_prod_le_sum_cubes_third (a b c : ℝ) (ha : 0 ≤ a) (hb : 0 ≤ b)
    (hc : 0 ≤ c) (hsum : a + b + c = 1) : a * b * c ≤ 1 / 27 := by
  have hcube : (a + b + c) ^ 3 = 1 := by rw [hsum]; norm_num
  nlinarith [hcube, mul_nonneg ha (sq_nonneg (a - b)), mul_nonneg hb (sq_nonneg (a - b)),
    mul_nonneg hc (sq_nonneg (a - b)), mul_nonneg ha (sq_nonneg (b - c)),
    mul_nonneg hb (sq_nonneg (b - c)), mul_nonneg hc (sq_nonneg (b - c)),
    mul_nonneg ha (sq_nonneg (c - a)), mul_nonneg hb (sq_nonneg (c - a)),
    mul_nonneg hc (sq_nonneg (c - a)), mul_nonneg (mul_nonneg ha hb) hc]
