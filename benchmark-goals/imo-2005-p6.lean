import Mathlib

theorem imo_2005_p6 {participants : Type} [Fintype participants] [DecidableEq participants]
    (solved : Fin 6 → Finset participants)
    (h : ∀ i j, i ≠ j → (solved i ∩ solved j).card > (2 * Fintype.card participants : ℝ) / 5)
    (h' : ∀ i : participants, ∃ p : Fin 6, i ∉ solved p) :
    ∃ s : Finset participants, s.card ≥ 2 ∧
    (∀ i ∈ s, ∃ p : Finset (Fin 6), p.card = 5 ∧ ∀ j, j ∈ p ↔ i ∈ solved j) := by
  sorry
