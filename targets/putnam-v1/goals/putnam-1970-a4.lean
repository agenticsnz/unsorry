import Mathlib

open Metric Set EuclideanGeometry Filter Topology

theorem putnam_1970_a4 (x : ℕ → ℝ)
(hxlim : Tendsto (fun n => x (n+2) - x n) atTop (𝓝 0))
: Tendsto (fun n => (x (n+1) - x (n))/(n+1)) atTop (𝓝 0) := by
  sorry
