import Mathlib.MeasureTheory.Measure.Lebesgue.VolumeOfBalls

/-- The area of the closed disk of radius `1/2` in the Euclidean plane is `π / 4`. -/
theorem putnam_1967_a5_volume_closedBall_half_eq :
    (MeasureTheory.volume (Metric.closedBall (0 : EuclideanSpace ℝ (Fin 2)) (1/2))).toReal
      = Real.pi / 4 := by
  rw [EuclideanSpace.volume_closedBall_fin_two, ENNReal.toReal_mul, ENNReal.toReal_pow,
    ENNReal.toReal_ofReal (by norm_num), ENNReal.toReal_ofReal Real.pi_nonneg]
  ring
