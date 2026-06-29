import Mathlib

open List Lex

theorem brualdi_ch4_35 (r n M : ℕ) (hM : M = ((@Finset.univ (Fin n)).powersetCard r).card)
    (A : Fin M → (Finset.powersetCard r (@Finset.univ (Fin n) _))) :
    ∀ i j, (List.Lex (fun x1 x2 : Fin n => x1 ≤ x2)
    (Finset.sort (· ≤ ·) (A i)) (Finset.sort (· ≤ ·) (A j))) →
    (List.Lex (fun x1 x2 : Fin n => x1 ≤ x2)
    (Finset.sort (· ≤ ·) (A j)ᶜ) (Finset.sort (· ≤ ·) (A i)ᶜ)) := by
  sorry
