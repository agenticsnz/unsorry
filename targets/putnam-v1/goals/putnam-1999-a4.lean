import Mathlib

open Filter Topology Metric
noncomputable abbrev putnam_1999_a4_solution : ℝ := 9/32

theorem putnam_1999_a4 : Tendsto (fun i => ∑ m ∈ Finset.range i, ∑' n : ℕ, (((m + 1)^2*(n+1))/(3^(m + 1) * ((n+1)*3^(m + 1) + (m + 1)*3^(n+1))) : ℝ)) atTop (𝓝 putnam_1999_a4_solution) := by
  sorry
