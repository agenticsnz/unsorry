import Mathlib

universe u
structure IsTournament {V : Type u} (G : Digraph V) : Prop where
  irrefl : ∀ (u : V), ¬ G.Adj u u
  adj : ∀ (u v : V), u ≠ v → (G.Adj u v ↔ ¬ G.Adj v u)
inductive Digraph.Walk {V : Type u} (G : Digraph V) : V → V → Type u
  | nil {u : V} (h : G.Adj u u) : Digraph.Walk G u u
  | cons {u v w : V} (h : G.Adj u v) (p : Digraph.Walk G v w) : Digraph.Walk G u w
  deriving DecidableEq
structure Digraph.StronglyConnected {V : Type u} (G : Digraph V) : Prop where
  exists_walk ⦃u v : V⦄ (neq : u ≠ v) : Nonempty (Digraph.Walk G u v)
def Digraph.Walk.support {V : Type u} {G : Digraph V} {u v : V} : Digraph.Walk G u v → List V
  | .nil h => [u]
  | .cons _ p => u :: p.support
def Digraph.Walk.IsPath {V : Type u} {G : Digraph V} {u v : V} (p : Digraph.Walk G u v) : Prop :=
  p.support.Nodup
structure Digraph.Walk.IsHamiltonianCycle
    {V : Type u} {G : Digraph V} {u : V} (p : Digraph.Walk G u u) : Prop where
  is_path : p.IsPath
  visit_all (v : V) : v ∈ p.support

theorem brualdi_ch13_9 {V : Type u} (T : Digraph V) (hT : IsTournament T) :
    T.StronglyConnected ↔
    ∃ (u : V) (p : T.Walk u u), p.IsHamiltonianCycle := by
  sorry
