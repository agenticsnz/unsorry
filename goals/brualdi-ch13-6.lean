import Mathlib

universe u
inductive Digraph.Walk {V : Type u} (G : Digraph V) : V → V → Type u
  | nil {u : V} (h : G.Adj u u) : Digraph.Walk G u u
  | cons {u v w : V} (h : G.Adj u v) (p : Digraph.Walk G v w) : Digraph.Walk G u w
  deriving DecidableEq
structure Digraph.StronglyConnected {V : Type u} (G : Digraph V) : Prop where
  exists_walk ⦃u v : V⦄ (neq : u ≠ v) : Nonempty (Digraph.Walk G u v)
def Digraph.Walk.support {V : Type u} {G : Digraph V} {u v : V} : Digraph.Walk G u v → List V
  | .nil h => [u]
  | .cons _ p => u :: p.support

theorem brualdi_ch13_6 {V : Type u} (T : Digraph V) :
    T.StronglyConnected ↔ ∃ (u : V) (p : T.Walk u u), ∀ v : V, v ∈ p.support := by
  sorry
