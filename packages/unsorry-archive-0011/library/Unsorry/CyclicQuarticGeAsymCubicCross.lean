import Mathlib.Data.Real.Basic
import Mathlib.Tactic.Linarith

/-- For nonnegative reals `a`, `b`, `c`, the cyclic sum of `a ^ 3 * b` is bounded by
the sum of fourth powers.  The key term-by-term bound is `4 * a ^ 3 * b ≤ 3 * a ^ 4 + b ^ 4`,
which follows from `3 * a ^ 4 - 4 * a ^ 3 * b + b ^ 4 = (a - b) ^ 2 * (3 * a ^ 2 + 2 * a * b + b ^ 2)`
together with `3 * a ^ 2 + 2 * a * b + b ^ 2 = 2 * a ^ 2 + (a + b) ^ 2 ≥ 0`.  Summing the three
cyclic instances gives the claim, so the sign hypotheses are not actually needed. -/
theorem cyclic_quartic_ge_asym_cubic_cross (a b c : ℝ) (_ha : 0 ≤ a) (_hb : 0 ≤ b)
    (_hc : 0 ≤ c) : a ^ 3 * b + b ^ 3 * c + c ^ 3 * a ≤ a ^ 4 + b ^ 4 + c ^ 4 := by
  nlinarith [sq_nonneg (a ^ 2 - b ^ 2), sq_nonneg (b ^ 2 - c ^ 2), sq_nonneg (c ^ 2 - a ^ 2),
    mul_nonneg (sq_nonneg (a - b)) (sq_nonneg a), mul_nonneg (sq_nonneg (b - c)) (sq_nonneg b),
    mul_nonneg (sq_nonneg (c - a)) (sq_nonneg c)]
