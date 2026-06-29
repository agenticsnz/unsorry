import Mathlib

open Set Function Filter Topology Polynomial Real
noncomputable abbrev putnam_1982_b3_solution : ℝ := 4/3 * (Real.sqrt 2 - 1)

theorem putnam_1982_b3 (p : ℕ → ℝ)
(hp : p = fun n : ℕ => ({(c, d) : Finset.Icc 1 n × Finset.Icc 1 n | ∃ m : ℕ, m^2 = c + d}.ncard : ℝ) / n^2)
: Tendsto (fun n : ℕ => p n * Real.sqrt n) atTop (𝓝 putnam_1982_b3_solution) := by
  sorry
