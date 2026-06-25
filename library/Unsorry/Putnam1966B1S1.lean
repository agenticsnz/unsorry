import Mathlib.Analysis.InnerProductSpace.PiL2

/-- The squared Euclidean distance between two points of the plane equals the
sum of the squared differences of their coordinates. -/
theorem dist_sq_eq_coord_sq (p q : EuclideanSpace ℝ (Fin 2)) :
    (dist p q) ^ 2 = (p 0 - q 0) ^ 2 + (p 1 - q 1) ^ 2 := by
  rw [EuclideanSpace.dist_eq,
    Real.sq_sqrt (Finset.sum_nonneg fun i _ => by positivity), Fin.sum_univ_two,
    Real.dist_eq, Real.dist_eq, sq_abs, sq_abs]
