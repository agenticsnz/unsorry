import Mathlib

def S := Finset.Icc 1 1000000

theorem imo_2003_p1 (A : Finset S) (hA: A.card = 101):
    ∃ x : Function.Embedding (Fin 100) S,
    ∀ i j, i ≠ j → Disjoint { a.1 + (x i).1 | a ∈ A } { a.1 + (x j).1 | a ∈ A } := by
  sorry
