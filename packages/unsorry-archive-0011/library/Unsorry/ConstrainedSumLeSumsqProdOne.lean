import Mathlib.Analysis.MeanInequalities

/-- For positive reals with unit product, the sum is bounded by the sum of squares.

The proof combines two classical facts. First, three-variable arithmetic-mean
inequality (`Real.geom_mean_le_arith_mean3_weighted` with equal weights `1/3`)
gives `1 = (a*b*c)^(1/3) ≤ (a+b+c)/3`, hence `a + b + c ≥ 3`. Second, the
identity `3(a²+b²+c²) - (a+b+c)² = (a-b)² + (b-c)² + (c-a)²` shows
`(a+b+c)² ≤ 3(a²+b²+c²)`. Writing `s = a+b+c ≥ 3`, we get
`3(a²+b²+c²) ≥ s² ≥ 3s`, so `a²+b²+c² ≥ s = a+b+c`. -/
theorem constrained_sum_le_sumsq_prod_one (a b c : ℝ)
    (ha : 0 < a) (hb : 0 < b) (hc : 0 < c) (habc : a * b * c = 1) :
    a + b + c ≤ a^2 + b^2 + c^2 := by
  have h3 : (3 : ℝ) ≤ a + b + c := by
    have key := Real.geom_mean_le_arith_mean3_weighted
      (by norm_num : (0:ℝ) ≤ 1/3) (by norm_num : (0:ℝ) ≤ 1/3)
      (by norm_num : (0:ℝ) ≤ 1/3) ha.le hb.le hc.le (by norm_num)
    rw [← Real.mul_rpow ha.le hb.le, ← Real.mul_rpow (mul_nonneg ha.le hb.le) hc.le,
      habc, Real.one_rpow] at key
    linarith
  nlinarith [sq_nonneg (a - b), sq_nonneg (b - c), sq_nonneg (c - a), h3,
    mul_pos (mul_pos ha hb) hc]
