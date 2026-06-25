import Mathlib

theorem brualdi_ch5_51 {X : Type} [DecidableEq X] (R S : Rel X X) [IsPartialOrder X R]
    [IsPartialOrder X S] (le : R < S) :
    ∃ (p q : X), S p q ∧ ¬ R p q ∧
    IsPartialOrder X (R ⊔ fun x y ↦ if x = p ∧ y = q then true else false) := by
  sorry
