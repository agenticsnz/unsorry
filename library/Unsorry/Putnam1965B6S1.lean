import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Normed.Module.RCLike.Real
import Mathlib.Data.Real.Sqrt

/-!
# Two circles in the plane intersect iff their radii bracket the centre distance

For two circles in the Euclidean plane, centred at `P` and `Q` with radii `r` and `s`,
the intersection of the circles is nonempty exactly when `|r - s| ≤ dist P Q ≤ r + s`.

The forward implication is the triangle inequality (and its reverse form).  The backward
implication is witnessed by an explicit point: the foot of the construction lies on the
line `PQ`, offset perpendicularly by an amount whose square is nonnegative precisely under
the bracketing hypotheses (a form of Heron's relation).
-/

theorem circle_inter_nonempty_iff_dist_le (P Q : EuclideanSpace ℝ (Fin 2)) (r s : ℝ)
    (hr : 0 ≤ r) (hs : 0 ≤ s) :
    (Metric.sphere P r ∩ Metric.sphere Q s).Nonempty ↔
      |r - s| ≤ dist P Q ∧ dist P Q ≤ r + s := by
  constructor
  · -- A common point forces the bracketing inequalities.
    rintro ⟨X, hXP, hXQ⟩
    rw [Metric.mem_sphere] at hXP hXQ
    refine ⟨?_, ?_⟩
    · have h := abs_dist_sub_le P Q X
      rwa [dist_comm P X, dist_comm Q X, hXP, hXQ] at h
    · have h := dist_triangle P X Q
      rwa [dist_comm P X, hXP, hXQ] at h
  · -- The bracketing inequalities supply a common point.
    rintro ⟨h1, h2⟩
    rcases eq_or_lt_of_le (dist_nonneg : (0 : ℝ) ≤ dist P Q) with hd0 | hdpos
    · -- Coincident centres: the hypotheses force `P = Q` and `r = s`.
      have hPQ : P = Q := dist_eq_zero.mp hd0.symm
      have h1' : |r - s| ≤ 0 := by rw [hd0]; exact h1
      have hrs : r = s := sub_eq_zero.mp (abs_eq_zero.mp (le_antisymm h1' (abs_nonneg _)))
      obtain ⟨X, hX⟩ := (NormedSpace.sphere_nonempty (x := P) (r := r)).mpr hr
      exact ⟨X, hX, by rw [← hPQ, ← hrs]; exact hX⟩
    · -- Distinct centres: build the point explicitly.
      set D := dist P Q ^ 2 with hDdef
      have hDpos : 0 < D := by rw [hDdef]; exact pow_pos hdpos 2
      have hDne : D ≠ 0 := hDpos.ne'
      have hD_coord : D = (Q 0 - P 0) ^ 2 + (Q 1 - P 1) ^ 2 := by
        rw [hDdef, EuclideanSpace.dist_sq_eq, Fin.sum_univ_two]
        simp only [Real.dist_eq, sq_abs]
        ring
      set a := (D + r ^ 2 - s ^ 2) / (2 * D) with hadef
      have hbsq_nonneg : 0 ≤ r ^ 2 / D - a ^ 2 := by
        have hfrac : r ^ 2 / D - a ^ 2
            = (4 * D * r ^ 2 - (D + r ^ 2 - s ^ 2) ^ 2) / (4 * D ^ 2) := by
          rw [hadef]; field_simp; ring
        rw [hfrac]
        apply div_nonneg
        · have hfac : 4 * D * r ^ 2 - (D + r ^ 2 - s ^ 2) ^ 2
              = (r + s - dist P Q) * (dist P Q - r + s) * (dist P Q + r - s)
                * (dist P Q + r + s) := by
            rw [hDdef]; ring
          rw [hfac]
          have hf1 : 0 ≤ r + s - dist P Q := by linarith
          have hf2 : 0 ≤ dist P Q - r + s := by have := (abs_le.mp h1).2; linarith
          have hf3 : 0 ≤ dist P Q + r - s := by have := (abs_le.mp h1).1; linarith
          have hf4 : 0 ≤ dist P Q + r + s := by linarith [hdpos.le]
          exact mul_nonneg (mul_nonneg (mul_nonneg hf1 hf2) hf3) hf4
        · positivity
      set b := Real.sqrt (r ^ 2 / D - a ^ 2) with hbdef
      have hb2 : b ^ 2 = r ^ 2 / D - a ^ 2 := by rw [hbdef]; exact Real.sq_sqrt hbsq_nonneg
      have hkey1 : (a ^ 2 + b ^ 2) * D = r ^ 2 := by
        have hsum : a ^ 2 + b ^ 2 = r ^ 2 / D := by rw [hb2]; ring
        rw [hsum]; exact div_mul_cancel₀ (r ^ 2) hDne
      have h2aD : a * (2 * D) = D + r ^ 2 - s ^ 2 := by
        rw [hadef]
        exact div_mul_cancel₀ (D + r ^ 2 - s ^ 2) (mul_ne_zero (by norm_num) hDne)
      have hkey2 : ((a - 1) ^ 2 + b ^ 2) * D = s ^ 2 := by
        have expand : ((a - 1) ^ 2 + b ^ 2) * D
            = (a ^ 2 + b ^ 2) * D - a * (2 * D) + D := by ring
        rw [expand, hkey1, h2aD]; ring
      set X : EuclideanSpace ℝ (Fin 2) :=
        !₂[P 0 + a * (Q 0 - P 0) - b * (Q 1 - P 1),
           P 1 + a * (Q 1 - P 1) + b * (Q 0 - P 0)] with hXdef
      have hX0 : X 0 = P 0 + a * (Q 0 - P 0) - b * (Q 1 - P 1) := by
        simp only [hXdef, PiLp.toLp_apply, Matrix.cons_val_zero]
      have hX1 : X 1 = P 1 + a * (Q 1 - P 1) + b * (Q 0 - P 0) := by
        simp only [hXdef, PiLp.toLp_apply, Matrix.cons_val_one, Matrix.cons_val_zero]
      refine ⟨X, ?_, ?_⟩
      · rw [Metric.mem_sphere]
        have hsq : dist X P ^ 2 = r ^ 2 := by
          rw [EuclideanSpace.dist_sq_eq, Fin.sum_univ_two]
          simp only [Real.dist_eq, sq_abs, hX0, hX1]
          linear_combination hkey1 - (a ^ 2 + b ^ 2) * hD_coord
        rw [← Real.sqrt_sq (dist_nonneg : (0 : ℝ) ≤ dist X P), hsq, Real.sqrt_sq hr]
      · rw [Metric.mem_sphere]
        have hsq : dist X Q ^ 2 = s ^ 2 := by
          rw [EuclideanSpace.dist_sq_eq, Fin.sum_univ_two]
          simp only [Real.dist_eq, sq_abs, hX0, hX1]
          linear_combination hkey2 - ((a - 1) ^ 2 + b ^ 2) * hD_coord
        rw [← Real.sqrt_sq (dist_nonneg : (0 : ℝ) ≤ dist X Q), hsq, Real.sqrt_sq hs]
