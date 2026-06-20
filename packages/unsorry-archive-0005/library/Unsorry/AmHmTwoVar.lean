import Mathlib

/-- Goal `am-hm-two-var`: the two-variable AM–HM inequality
`4/(a+b) ≤ 1/a + 1/b` for positive reals. See `library/index/`. Cross-multiplying
reduces it to `(a-b)² ≥ 0`. -/
theorem am_hm_two_var (a b : ℝ) (ha : 0 < a) (hb : 0 < b) : 4 / (a + b) ≤ 1 / a + 1 / b := by
  have ha' : a ≠ 0 := ha.ne'
  have hb' : b ≠ 0 := hb.ne'
  have hab : 0 < a + b := by linarith
  have hab' : a + b ≠ 0 := hab.ne'
  have e : (1 / a + 1 / b) - 4 / (a + b) = (a - b) ^ 2 / (a * b * (a + b)) := by
    field_simp; ring
  have hpos : 0 ≤ (1 / a + 1 / b) - 4 / (a + b) := by rw [e]; positivity
  linarith
