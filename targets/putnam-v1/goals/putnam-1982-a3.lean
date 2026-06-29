import Mathlib

open Set Function Filter Topology Polynomial Real
noncomputable abbrev putnam_1982_a3_solution : ℝ := (Real.pi / 2) * log Real.pi

theorem putnam_1982_a3 :
  Tendsto (fun t ↦ ∫ x in (0)..t, (arctan (Real.pi * x) - arctan x) / x) atTop (𝓝 putnam_1982_a3_solution) := by
  sorry
