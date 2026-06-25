import Mathlib

open SimpleGraph Finset
abbrev Ladies := Fin 100

theorem balticway_2015_p7 (had_tea: SimpleGraph (Ladies)) [DecidableRel had_tea.Adj]
    (h_had_tea_with_56: ∀ l : Ladies, had_tea.degree l = 56)
    (h_board: ∃ board : Finset Ladies, board.card = 50 ∧ had_tea.IsClique board) :
    ∃ group1 group2: Finset Ladies,
      group1 ∪ group2 = Finset.univ
      ∧ Disjoint group1 group2
      ∧ had_tea.IsClique group1
      ∧ had_tea.IsClique group2 := by
  sorry
