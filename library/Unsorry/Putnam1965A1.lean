import Mathlib.Geometry.Euclidean.Triangle
import Mathlib.Analysis.InnerProductSpace.PiL2

/-!
# Putnam 1965 A1

Let `ABC` be a triangle with `∠CAB < ∠BCA < π/2 < ∠ABC`.  Pick `X` on line `BC` with
`∠XAB = (π - ∠CAB)/2` and `AX = AB`, and `Y` on line `CA` with `∠YBC = (π - ∠ABC)/2`
and `BY = AB`.  Then `∠CAB = π/15`.

The proof is angle chasing.  Writing `a = ∠CAB`, `b = ∠ABC`, `c = ∠BCA`, the triangle gives
`a + b + c = π`, and the ordering forces `a < π/4`.  The isosceles triangle `ABX` together with
the position of `X` on line `BC` gives `(π + a)/4 + b = π`.  The isosceles triangle `ABY`
together with the position of `Y` on line `CA` (which must place `C` between `A` and `Y`) gives
`4*a + b = π`.  Solving the two linear relations yields `a = π/15`.
-/

open EuclideanGeometry Real

noncomputable abbrev putnam_1965_a1_solution : ℝ := Real.pi / 15

theorem putnam_1965_a1 (A B C X Y : EuclideanSpace ℝ (Fin 2))
    (hABC : ¬Collinear ℝ {A, B, C})
    (hangles : ∠ C A B < ∠ B C A ∧ ∠ B C A < π/2 ∧ π/2 < ∠ A B C)
    (hX : Collinear ℝ {X, B, C} ∧ ∠ X A B = (π - ∠ C A B)/2 ∧ dist A X = dist A B)
    (hY : Collinear ℝ {Y, C, A} ∧ ∠ Y B C = (π - ∠ A B C)/2 ∧ dist B Y = dist A B) :
    ∠ C A B = putnam_1965_a1_solution := by
  show ∠ C A B = π / 15
  obtain ⟨hXcol, hXang, hXdist⟩ := hX
  obtain ⟨hYcol, hYang, hYdist⟩ := hY
  obtain ⟨hang1, hang2, hang3⟩ := hangles
  -- pairwise distinctness of the triangle's vertices
  have hAB : A ≠ B := ne₁₂_of_not_collinear hABC
  have hAC : A ≠ C := ne₁₃_of_not_collinear hABC
  have hBC : B ≠ C := ne₂₃_of_not_collinear hABC
  have hBA : B ≠ A := hAB.symm
  have hCB : C ≠ B := hBC.symm
  have hpi := Real.pi_pos
  -- the sum of the angles of the triangle
  have hsum : ∠ C A B + ∠ A B C + ∠ B C A = π := angle_add_angle_add_angle_eq_pi B hAC
  -- the auxiliary points are not the apexes of their isosceles triangles
  have hABpos : (0 : ℝ) < dist A B := dist_pos.mpr hAB
  have hAX : A ≠ X := by
    intro h; rw [← h, dist_self] at hXdist; exact hABpos.ne' hXdist.symm
  have hBY : B ≠ Y := by
    intro h; rw [← h, dist_self] at hYdist; exact hABpos.ne' hYdist.symm
  -- isosceles triangle `ABX` (apex `A`) and its angle sum
  have hiso : ∠ A X B = ∠ A B X := angle_eq_angle_of_dist_eq hXdist
  have htri : ∠ X A B + ∠ A B X + ∠ B X A = π := angle_add_angle_add_angle_eq_pi B hAX
  have hcomm1 : ∠ B X A = ∠ A X B := angle_comm B X A
  -- analyse where `X` sits on line `BC`
  rcases collinear_iff_eq_or_eq_or_angle_eq_zero_or_angle_eq_pi.mp hXcol with hh | hh | hh | hh
  · -- `X = B` is impossible: it would force `∠ C A B = π`
    rw [hh, angle_self_of_ne hBA] at hXang
    linarith [hsum, hang3, angle_nonneg B C A]
  · -- `C = B` contradicts distinctness
    exact absurd hh hCB
  · -- `∠ X B C = 0` would force `∠ A B X = ∠ A B C`, too small to be obtuse
    rcases angle_eq_zero_iff_ne_and_wbtw.mp hh with ⟨hne, hw⟩ | ⟨hne, hw⟩
    · have hABXeq : ∠ A B X = ∠ A B C := hw.angle_eq_right A hne
      linarith [htri, hcomm1, hiso, hXang, hABXeq, hang1, hang2, hang3]
    · have hABXeq : ∠ A B C = ∠ A B X := hw.angle_eq_right A hne
      linarith [htri, hcomm1, hiso, hXang, hABXeq, hang1, hang2, hang3]
  · -- `∠ X B C = π`: `B` lies between `X` and `C`, giving `∠ A B X + ∠ A B C = π`
    have hXgood : ∠ A B X + ∠ A B C = π := angle_add_angle_eq_pi_of_angle_eq_pi A hh
    -- isosceles triangle `ABY` (apex `B`)
    have hisoY : ∠ B Y A = ∠ B A Y := angle_eq_angle_of_dist_eq (hYdist.trans (dist_comm A B))
    -- `Y` is distinct from `A` and `C`
    have hAY : A ≠ Y := by
      intro h; rw [← h] at hYang; linarith [hang3, Real.pi_pos]
    have hCY : C ≠ Y := by
      intro h; rw [← h, angle_self_of_ne hCB] at hYang
      linarith [angle_lt_pi_of_not_collinear hABC]
    have hbpi : ∠ A B C < π := angle_lt_pi_of_not_collinear hABC
    have commBAC : ∠ B A C = ∠ C A B := angle_comm B A C
    -- analyse where `Y` sits on line `CA`
    rcases hYcol.wbtw_or_wbtw_or_wbtw with hw | hw | hw
    · -- `C` between `Y` and `A`: the genuine configuration
      have sC : Sbtw ℝ Y C A := ⟨hw, hCY, hAC.symm⟩
      have hCYrel : ∠ B C Y + ∠ B C A = π :=
        angle_add_angle_eq_pi_of_angle_eq_pi B sC.angle₁₂₃_eq_pi
      have hAArel : ∠ B A C = ∠ B A Y := sC.symm.angle_eq_right B
      have hYYrel : ∠ B Y C = ∠ B Y A := sC.angle_eq_right B
      have htriY : ∠ Y B C + ∠ B C Y + ∠ C Y B = π := angle_add_angle_add_angle_eq_pi C hBY
      have commCYB : ∠ C Y B = ∠ B Y C := angle_comm C Y B
      linarith [hXgood, htri, hcomm1, hiso, hXang, hCYrel, hAArel, hYYrel, hisoY,
        htriY, hYang, commCYB, commBAC, hsum]
    · -- `A` between `C` and `Y`: impossible, it makes `∠ A B Y` negative
      have sA : Sbtw ℝ C A Y := ⟨hw, hAC, hAY⟩
      have hAYrel : ∠ B A C + ∠ B A Y = π :=
        angle_add_angle_eq_pi_of_angle_eq_pi B sA.angle₁₂₃_eq_pi
      have htriY : ∠ Y A B + ∠ A B Y + ∠ B Y A = π := angle_add_angle_add_angle_eq_pi B hAY
      have commYAB : ∠ Y A B = ∠ B A Y := angle_comm Y A B
      linarith [hAYrel, commBAC, hisoY, htriY, commYAB, angle_nonneg A B Y, hang1, hang2]
    · -- `Y` between `A` and `C`: impossible, it forces `∠ B C A < ∠ C A B`
      have sY : Sbtw ℝ A Y C := ⟨hw, hAY.symm, hCY.symm⟩
      have hCYrel2 : ∠ B C Y = ∠ B C A := sY.symm.angle_eq_right B
      have hAYrel2 : ∠ B A Y = ∠ B A C := sY.angle_eq_right B
      have hYrel2 : ∠ B Y A + ∠ B Y C = π :=
        angle_add_angle_eq_pi_of_angle_eq_pi B sY.angle₁₂₃_eq_pi
      have htriY : ∠ Y B C + ∠ B C Y + ∠ C Y B = π := angle_add_angle_add_angle_eq_pi C hBY
      have commCYB : ∠ C Y B = ∠ B Y C := angle_comm C Y B
      linarith [hCYrel2, hAYrel2, hYrel2, hisoY, htriY, hYang, commCYB, commBAC, hbpi, hang1]
