import Mathlib

def balanced (S : Set (EuclideanSpace ℝ (Fin 2))) : Prop :=
  ∀ A ∈ S, ∀ B ∈ S, A ≠ B → (∃ C ∈ S, dist A C = dist B C)
def centre_free (S : Set (EuclideanSpace ℝ (Fin 2))) : Prop :=
  ∀ A ∈ S, ∀ B ∈ S, ∀ C ∈ S, A ≠ B → B ≠ C → A ≠ C →
    ¬ (∃ P ∈ S, dist A P = dist B P ∧ dist B P = dist C P)

theorem imo_2015_p1 : (∀ n ≥ 3, ∃ (S : Finset (EuclideanSpace ℝ (Fin 2))), balanced S ∧ S.card = n) ∧
    {n | n ≥ 3 ∧ (∃ (S : Finset (EuclideanSpace ℝ (Fin 2))), balanced S ∧ centre_free S ∧ S.card = n)} =
    (({n | n ≥ 3 ∧ Odd n}) : Set ℕ ) := by
  sorry
