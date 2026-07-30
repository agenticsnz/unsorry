import Mathlib.Tactic.Ring

/-- Goal `quartic-x4-plus-x2-plus-one-dvd-by-minus-factor`: `(x²-x+1) ∣ (x⁴+x²+1)` over `ℤ`. -/
theorem quartic_x4_plus_x2_plus_one_dvd_by_minus_factor (x : ℤ) : (x ^ 2 - x + 1) ∣ (x ^ 4 + x ^ 2 + 1) :=
  ⟨x ^ 2 + x + 1, by ring⟩
