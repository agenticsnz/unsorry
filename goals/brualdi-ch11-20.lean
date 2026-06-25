import Mathlib

theorem brualdi_ch11_20 {V : Type*} [Fintype V] (n : ℕ) (hn : n ≥ 1) (hV : Fintype.card V = n)
    (G : SimpleGraph V) (h : (n - 1) * (n - 2) / 2 + 1 ≤ (SimpleGraph.edgeSet G).ncard) :
    G.Connected := by
  sorry
