import Mathlib

theorem circle_inter_nonempty_iff_dist_le (P Q : EuclideanSpace ℝ (Fin 2)) (r s : ℝ) (hr : 0 ≤ r) (hs : 0 ≤ s) : (Metric.sphere P r ∩ Metric.sphere Q s).Nonempty ↔ |r - s| ≤ dist P Q ∧ dist P Q ≤ r + s := by
  sorry
