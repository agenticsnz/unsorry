import Mathlib.Tactic.Ring

/-- Goal `sextic-x6-plus-x3-plus-one-composite-shift`: `(n⁶+n³+1) ∣ (n⁹-1)` over `ℤ`
(factorisation `n⁹-1 = (n³-1)(n⁶+n³+1)`). -/
theorem sextic_x6_plus_x3_plus_one_dvd_pow_nine_sub_one (n : ℤ) : (n ^ 6 + n ^ 3 + 1) ∣ (n ^ 9 - 1) :=
  ⟨n ^ 3 - 1, by ring⟩
