import Mathlib

/-- Goal `sumsq-times-recip-sq-ge-nine`:
`9 ≤ (a²+b²+c²)(1/a²+1/b²+1/c²)` for positive reals (Cauchy–Schwarz). The gap is
`((a²-b²)²c² + (b²-c²)²a² + (a²-c²)²b²)/(a²b²c²) ≥ 0`. See `library/index/`. -/
theorem sumsq_times_recip_sq_ge_nine (a b c : ℝ) (ha : 0 < a) (hb : 0 < b)
    (hc : 0 < c) : 9 ≤ (a ^ 2 + b ^ 2 + c ^ 2) * (1 / a ^ 2 + 1 / b ^ 2 + 1 / c ^ 2) := by
  have ha2 : a ^ 2 ≠ 0 := by positivity
  have hb2 : b ^ 2 ≠ 0 := by positivity
  have hc2 : c ^ 2 ≠ 0 := by positivity
  rw [← sub_nonneg]
  have h : (a ^ 2 + b ^ 2 + c ^ 2) * (1 / a ^ 2 + 1 / b ^ 2 + 1 / c ^ 2) - 9
      = ((a ^ 2 - b ^ 2) ^ 2 * c ^ 2 + (b ^ 2 - c ^ 2) ^ 2 * a ^ 2
          + (a ^ 2 - c ^ 2) ^ 2 * b ^ 2) / (a ^ 2 * b ^ 2 * c ^ 2) := by
    field_simp
    ring
  rw [h]
  positivity
