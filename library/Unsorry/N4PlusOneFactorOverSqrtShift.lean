import Mathlib.Tactic.Ring

/-- Goal `n4-plus-one-factor-over-sqrt-shift`: `(2n²-2n+1) ∣ (4n⁴+1)` over `ℤ`
(Sophie-Germain factorisation `4n⁴+1 = (2n²-2n+1)(2n²+2n+1)`). -/
theorem n4_plus_one_factor_over_sqrt_shift (n : ℤ) : (2 * n ^ 2 - 2 * n + 1) ∣ (4 * n ^ 4 + 1) :=
  ⟨2 * n ^ 2 + 2 * n + 1, by ring⟩
