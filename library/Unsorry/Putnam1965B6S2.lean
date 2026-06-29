import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.LinearAlgebra.AffineSpace.FiniteDimensional

/-!
# The power of a point is constant along a chord line

Let `A ≠ B` be two points in the Euclidean plane and let `X` lie on the line through `A`
and `B`.  If `P` is any point equidistant (distance `r`) from `A` and `B` — that is, the
centre of a circle of radius `r` through `A` and `B` — then the quantity
`dist X P ^ 2 - r ^ 2`, the power of `X` with respect to that circle, depends only on `X`,
`A` and `B`, not on the choice of `P`.

The proof writes `X - A = t • (B - A)` using collinearity, and shows both powers equal the
common value `⟪X - A, X - B⟫_ℝ`.  The equidistance of `P` from `A` and `B` is exactly the
relation `2 ⟪B - A, P - A⟫ = ‖B - A‖ ^ 2` that makes the dependence on `P` cancel.
-/

open scoped InnerProductSpace

theorem power_of_point_const_along_chord (A B X P1 P2 : EuclideanSpace ℝ (Fin 2)) (r1 r2 : ℝ)
    (hAB : A ≠ B) (hX : Collinear ℝ ({X, A, B} : Set (EuclideanSpace ℝ (Fin 2))))
    (hP1A : dist P1 A = r1) (hP1B : dist P1 B = r1) (hP2A : dist P2 A = r2)
    (hP2B : dist P2 B = r2) :
    dist X P1 ^ 2 - r1 ^ 2 = dist X P2 ^ 2 - r2 ^ 2 := by
  -- Collinearity gives a direction `v` and coefficients expressing `X` and `B` from `A`.
  obtain ⟨v, hv⟩ := (collinear_iff_of_mem
    (show A ∈ ({X, A, B} : Set (EuclideanSpace ℝ (Fin 2))) by simp)).mp hX
  obtain ⟨cX, hcX⟩ := hv X (by simp)
  obtain ⟨cB, hcB⟩ := hv B (by simp)
  rw [vadd_eq_add] at hcX hcB
  have hXA : X - A = cX • v := by rw [hcX]; abel
  have hBA : B - A = cB • v := by rw [hcB]; abel
  have hcB0 : cB ≠ 0 := by
    intro h
    rw [h, zero_smul] at hBA
    exact hAB (sub_eq_zero.mp hBA).symm
  have hv_eq : v = cB⁻¹ • (B - A) := by
    rw [hBA, smul_smul, inv_mul_cancel₀ hcB0, one_smul]
  set t := cX * cB⁻¹ with ht
  have key_t : X - A = t • (B - A) := by rw [hXA, hv_eq, smul_smul, ht]
  have hXB : X - B = (t - 1) • (B - A) := by
    have e : X - B = (X - A) - (B - A) := by abel
    rw [e, key_t, sub_smul, one_smul]
  -- Per-point identity: the power equals the `P`-independent value `⟪X - A, X - B⟫`.
  have key : ∀ (P : EuclideanSpace ℝ (Fin 2)) (r : ℝ), dist P A = r → dist P B = r →
      dist X P ^ 2 - r ^ 2 = ⟪X - A, X - B⟫_ℝ := by
    intro P r hPA hPB
    have hr : r = ‖P - A‖ := by rw [← hPA, dist_eq_norm]
    -- Equidistance of `P` from `A` and `B`.
    have hcon : 2 * ⟪B - A, P - A⟫_ℝ = ‖B - A‖ ^ 2 := by
      have hsq : ‖(P - A) - (B - A)‖ ^ 2 = ‖P - A‖ ^ 2 := by
        rw [show (P - A) - (B - A) = P - B by abel, ← dist_eq_norm, ← dist_eq_norm, hPA, hPB]
      rw [norm_sub_sq_real, ← real_inner_comm (P - A) (B - A)] at hsq
      linarith
    have hRHS : ⟪X - A, X - B⟫_ℝ = t * (t - 1) * ‖B - A‖ ^ 2 := by
      rw [key_t, hXB, real_inner_smul_left, real_inner_smul_right,
        real_inner_self_eq_norm_sq]
      ring
    have hnorm : ‖t • (B - A)‖ ^ 2 = t ^ 2 * ‖B - A‖ ^ 2 := by
      rw [norm_smul, mul_pow, Real.norm_eq_abs, sq_abs]
    have hXP : X - P = t • (B - A) - (P - A) := by
      have e : X - P = (X - A) - (P - A) := by abel
      rw [e, key_t]
    have hLHS : dist X P ^ 2 - r ^ 2 = t * (t - 1) * ‖B - A‖ ^ 2 := by
      rw [dist_eq_norm, hr, hXP, norm_sub_sq_real, real_inner_smul_left, hnorm]
      linear_combination (-t) * hcon
    rw [hLHS, hRHS]
  rw [key P1 r1 hP1A hP1B, key P2 r2 hP2A hP2B]
