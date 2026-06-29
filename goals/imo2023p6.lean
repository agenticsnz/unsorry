import Mathlib

open scoped Cardinal EuclideanGeometry Real
open Affine Module
variable {V P : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V] [MetricSpace P]
variable [NormedAddTorsor V P] [Fact (finrank ℝ V = 2)]

theorem imo2023p6 {A B C A₁ B₁ C₁ A₂ B₂ C₂ : P}
    (affineIndependent_ABC : AffineIndependent ℝ ![A, B, C])
    (equilateral_ABC : (⟨_, affineIndependent_ABC⟩ : Triangle ℝ P).Equilateral)
    (A₁_mem_interior_ABC : A₁ ∈ (⟨_, affineIndependent_ABC⟩ : Triangle ℝ P).interior)
    (B₁_mem_interior_ABC : B₁ ∈ (⟨_, affineIndependent_ABC⟩ : Triangle ℝ P).interior)
    (C₁_mem_interior_ABC : C₁ ∈ (⟨_, affineIndependent_ABC⟩ : Triangle ℝ P).interior)
    (BA₁_eq_A₁C : dist B A₁ = dist A₁ C) (CB₁_eq_B₁A : dist C B₁ = dist B₁ A)
    (AC₁_eq_C₁B : dist A C₁ = dist C₁ B)
    (angle_BA₁C_add_angle_CB₁A_add_angle_AC₁B : ∠ B A₁ C + ∠ C B₁ A + ∠ A C₁ B = 8 / 3 * π)
    (A₂_mem_inf_BC₁_CB₁ : A₂ ∈ line[ℝ, B, C₁] ⊓ line[ℝ, C, B₁])
    (B₂_mem_inf_CA₁_AC₁ : B₂ ∈ line[ℝ, C, A₁] ⊓ line[ℝ, A, C₁])
    (C₂_mem_inf_AB₁_BA₁ : C₂ ∈ line[ℝ, A, B₁] ⊓ line[ℝ, B, A₁])
    (affineIndependent_A₁B₁C₁ : AffineIndependent ℝ ![A₁, B₁, C₁])
    (scalene_A₁B₁C₁ : (⟨_, affineIndependent_A₁B₁C₁⟩ : Triangle ℝ P).Scalene) :
    ∃ affineIndependent_AA₁A₂ : AffineIndependent ℝ ![A, A₁, A₂],
    ∃ affineIndependent_BB₁B₂ : AffineIndependent ℝ ![B, B₁, B₂],
    ∃ affineIndependent_CC₁C₂ : AffineIndependent ℝ ![C, C₁, C₂],
    2 ≤ #((⟨_, affineIndependent_AA₁A₂⟩ : Triangle ℝ P).circumsphere ∩
          (⟨_, affineIndependent_BB₁B₂⟩ : Triangle ℝ P).circumsphere ∩
          (⟨_, affineIndependent_CC₁C₂⟩ : Triangle ℝ P).circumsphere : Set P) := by
  sorry
