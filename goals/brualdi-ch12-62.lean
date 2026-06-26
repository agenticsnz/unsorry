import Mathlib

structure TwoConnected {V : Type*} (G : SimpleGraph V) : Prop where
  selfconnected : G.Connected
  remains_connected : ∀ x : V, ((⊤ : SimpleGraph.Subgraph G).deleteVerts {x}).coe.Connected

theorem brualdi_ch12_62 {V : Type*} (G : SimpleGraph V) : TwoConnected G ↔ ∀ x : V, ∀ e ∈ G.edgeSet,
    ∃ G' : SimpleGraph.Subgraph G, x ∈ G'.verts ∧ e ∈ G'.edgeSet ∧ G'.coe.IsCycles := by
  sorry
