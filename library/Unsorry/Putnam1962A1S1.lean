import Mathlib.Analysis.Convex.Hull
import Mathlib.Data.Real.Basic

/-- If no point of `B` lies in the convex hull of the rest of `B`, then the same
holds for every subset `A ⊆ B`: removing points cannot create a point that is a
convex combination of the others. -/
theorem convex_position_subset (A B : Set (ℝ × ℝ)) (hAB : A ⊆ B)
    (hB : ¬∃ t ∈ B, t ∈ convexHull ℝ (B \ {t})) :
    ¬∃ t ∈ A, t ∈ convexHull ℝ (A \ {t}) := by
  rintro ⟨t, htA, htConv⟩
  refine hB ⟨t, hAB htA, ?_⟩
  exact convexHull_mono (Set.diff_subset_diff_left hAB) htConv
