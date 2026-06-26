import Mathlib.Data.Int.Basic

/-- If `x y z` realize the minimal positive absolute-value sum among all triples
satisfying `P`, then no `P`-triple can have a strictly smaller positive sum.
Applying minimality to the witness `x1 y1 z1` yields `‖x‖+‖y‖+‖z‖ ≤ ‖x1‖+‖y1‖+‖z1‖`,
which directly contradicts the strict inequality `hsmall`. -/
theorem minimal_natAbs_sum_contradicts_strict_smaller (P : ℤ → ℤ → ℤ → Prop)
    (x y z x1 y1 z1 : ℤ) (hP1 : P x1 y1 z1)
    (hpos1 : 0 < Int.natAbs x1 + Int.natAbs y1 + Int.natAbs z1)
    (hmin : ∀ u v w, P u v w → 0 < Int.natAbs u + Int.natAbs v + Int.natAbs w →
      Int.natAbs x + Int.natAbs y + Int.natAbs z ≤ Int.natAbs u + Int.natAbs v + Int.natAbs w)
    (hsmall : Int.natAbs x1 + Int.natAbs y1 + Int.natAbs z1 <
      Int.natAbs x + Int.natAbs y + Int.natAbs z) : False := by
  have hle := hmin x1 y1 z1 hP1 hpos1
  omega
