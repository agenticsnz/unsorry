import Mathlib

theorem concentric_spheres_disjoint_of_radius_ne (P : EuclideanSpace ℝ (Fin 2)) (r s : ℝ) (h : r ≠ s) : ¬ (Metric.sphere P r ∩ Metric.sphere P s).Nonempty := by
  sorry
