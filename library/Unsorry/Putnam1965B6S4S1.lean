import Mathlib.Analysis.InnerProductSpace.EuclideanDist

theorem concentric_spheres_disjoint_of_radius_ne
    (P : EuclideanSpace ℝ (Fin 2)) (r s : ℝ) (h : r ≠ s) :
    ¬(Metric.sphere P r ∩ Metric.sphere P s).Nonempty := by
  intro ⟨x, hx⟩
  simp only [Set.mem_inter_iff, Metric.mem_sphere] at hx
  exact h (hx.1.symm.trans hx.2)
