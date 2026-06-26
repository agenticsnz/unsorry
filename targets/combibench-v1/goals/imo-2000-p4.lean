import Mathlib

abbrev Cards := Finset.Icc 1 100
abbrev Boxes := Fin 3
abbrev Trick := ℕ → Boxes
def trick_works (f : Cards → Boxes) (t : Trick) : Prop :=
  ∀ c₁ c₂ : Cards,
  (f c₁ = 0 → f c₂ = 1 → t (c₁.1 + c₂.1) = 2) ∧
  (f c₁ = 0 → f c₂ = 2 → t (c₁.1 + c₂.1) = 1) ∧
  (f c₁ = 1 → f c₂ = 2 → t (c₁.1 + c₂.1) = 0)

theorem imo_2000_p4 (good_allocations : Finset (Cards → Boxes))
    (h : ∀ f, f ∈ good_allocations ↔ Function.Surjective f ∧ ∃ (t : Trick), trick_works f t) :
    good_allocations.card = ((12) : ℕ ) := by
  sorry
