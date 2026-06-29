import Mathlib

structure Domino (n k : ℕ) where
  carrier : Finset (Fin n × Fin (2 * k))
  card : carrier.card = 2
  position : ∀ i ∈ carrier, ∀ j ∈ carrier, i ≠ j →
    (i.1.val = j.1.val ∧ (i.2.val + 1 = j.2.val ∨ j.2.val + 1 = i.2.val)) ∨
    (i.2.val = j.2.val ∧ (i.1.val + 1 = j.1.val ∨ j.1.val + 1 = i.1.val))
noncomputable instance {n k} : Fintype (Domino n k) :=
  Fintype.ofInjective Domino.carrier <| by
    rintro ⟨carrier, _⟩ ⟨carrier', _⟩ (rfl : carrier = carrier')
    rfl
structure PerfectCover (n k : ℕ) where
  d_set : Finset (Domino n k)
  d_card : d_set.card = n * k
  covers : ∀ i : Fin n × Fin (2 * k), ∃ d ∈ d_set, i ∈ d.carrier
noncomputable instance {n k} : Fintype (PerfectCover n k) :=
  Fintype.ofInjective PerfectCover.d_set <| by
    rintro ⟨d, _⟩ ⟨d', _⟩ (rfl : d = d')
    rfl

theorem brualdi_ch1_5 : Fintype.card (PerfectCover 3 2) = ((11) : ℕ ) := by
  sorry
