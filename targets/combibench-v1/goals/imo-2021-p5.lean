import Mathlib

def move (k : Fin 2021) (order : Fin 2021 ≃ Fin 2021) : Fin 2021 ≃ Fin 2021 :=
  order.trans (Equiv.swap (order (finRotate _ (order.symm k))) (order ((finRotate _).symm (order.symm k))))
def performMoves (originalOrder : Fin 2021 ≃ Fin 2021) : (Fin 2021) → (Fin 2021 ≃ Fin 2021)
  | 0 => originalOrder
  | ⟨n + 1, lt⟩ => move ⟨n, by omega⟩ (performMoves originalOrder ⟨n, lt_trans (by omega) lt⟩)

theorem imo_2021_p5 (originalOrder : Fin 2021 ≃ Fin 2021) :
    ∃ k, min (finRotate _ ((performMoves originalOrder k).symm k) : ℕ)
        ((finRotate _).symm ((performMoves originalOrder k).symm k) : ℕ) < (k : ℕ) ∧
      (k : ℕ) < max (finRotate _ ((performMoves originalOrder k).symm k) : ℕ)
        ((finRotate _).symm ((performMoves originalOrder k).symm k) : ℕ) := by
  sorry
