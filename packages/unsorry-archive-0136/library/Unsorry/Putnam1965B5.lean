import Mathlib

/-!
# Putnam 1965 B5

For a finite vertex type `K` with `V = Nat.card K` and `4 * E ≤ V ^ 2`, there is a
simple graph on `K` with exactly `E` edges in which no vertex is the endpoint of a
closed walk of length three.

The construction is a balanced two-sided graph: fix a half `A` of the vertices and
join only vertices of `A` to vertices of its complement.  Every edge then crosses
the split, so the endpoints always lie on opposite sides; a closed walk would have
to switch sides an even number of times, hence can never have length three.  A
balanced split offers `⌊V ^ 2 / 4⌋ ≥ E` crossing pairs, so we may retain exactly
`E` of them to hit the required count.
-/

theorem putnam_1965_b5 {K : Type*} [Fintype K] (V E : ℕ) (hV : V = Nat.card K)
    (hE : 4 * E ≤ V ^ 2) :
    ∃ G : SimpleGraph K, G.edgeSet.ncard = E ∧ ∀ a : K, ∀ w : G.Walk a a, w.length ≠ 3 := by
  classical
  -- A balanced split realises at least `E` crossing pairs.
  have key : ∀ n e : ℕ, 4 * e ≤ n ^ 2 → e ≤ n / 2 * (n - n / 2) := by
    intro n e h
    rcases Nat.even_or_odd n with ⟨m, hm⟩ | ⟨m, hm⟩
    · subst hm
      rw [show (m + m) / 2 = m by omega, show (m + m) - m = m by omega]
      have hsq : (m + m) ^ 2 = 4 * (m * m) := by ring
      rw [hsq] at h
      omega
    · subst hm
      rw [show (2 * m + 1) / 2 = m by omega, show (2 * m + 1) - m = m + 1 by omega]
      have hsq : (2 * m + 1) ^ 2 = 4 * (m * m) + 4 * m + 1 := by ring
      rw [hsq] at h
      have hexp : m * (m + 1) = m * m + m := by ring
      rw [hexp]
      omega
  have hcard_univ : (Finset.univ : Finset K).card = V := by
    rw [Finset.card_univ, ← Nat.card_eq_fintype_card]; exact hV.symm
  -- Choose one balanced half `A`.
  obtain ⟨A, -, hA_card⟩ :=
    Finset.exists_subset_card_eq (s := (Finset.univ : Finset K)) (n := V / 2)
      (by rw [hcard_univ]; exact Nat.div_le_self V 2)
  have hB_card : (Finset.univ \ A).card = V - V / 2 := by
    rw [Finset.card_sdiff_of_subset (Finset.subset_univ A), hcard_univ, hA_card]
  -- Pairing a vertex of `A` with one of the complement is injective into the
  -- unordered pairs, because the two sides are disjoint.
  have hinj : Set.InjOn (fun p : K × K => s(p.1, p.2)) ↑(A ×ˢ (Finset.univ \ A)) := by
    intro p hp q hq hpq
    rw [Finset.mem_coe, Finset.mem_product] at hp hq
    have hpq' : s(p.1, p.2) = s(q.1, q.2) := hpq
    rw [Sym2.eq_iff] at hpq'
    rcases hpq' with ⟨h1, h2⟩ | ⟨h1, h2⟩
    · exact Prod.ext_iff.mpr ⟨h1, h2⟩
    · exfalso
      have hp1A : p.1 ∈ A := hp.1
      rw [h1] at hp1A
      exact (Finset.mem_sdiff.mp hq.2).2 hp1A
  -- Retain exactly `E` of the crossing pairs.
  obtain ⟨t, ht_sub, ht_card⟩ :=
    Finset.exists_subset_card_eq
      (s := (A ×ˢ (Finset.univ \ A)).image (fun p : K × K => s(p.1, p.2))) (n := E)
      (by
        rw [Finset.card_image_of_injOn hinj, Finset.card_product, hA_card, hB_card]
        exact key V E hE)
  -- None of the retained pairs is a self-loop.
  have hno : ∀ e ∈ t, ¬ e.IsDiag := by
    intro e he
    have hcr := ht_sub he
    simp only [Finset.mem_image] at hcr
    obtain ⟨p, hp, hpe⟩ := hcr
    rw [Finset.mem_product] at hp
    rw [← hpe, Sym2.mk_isDiag_iff]
    intro heq
    have hp1A : p.1 ∈ A := hp.1
    rw [heq] at hp1A
    exact (Finset.mem_sdiff.mp hp.2).2 hp1A
  refine ⟨SimpleGraph.fromEdgeSet (↑t : Set (Sym2 K)), ?_, ?_⟩
  · -- The edge set is exactly the retained pairs, so it has `E` elements.
    have hedge : (SimpleGraph.fromEdgeSet (↑t : Set (Sym2 K))).edgeSet = (↑t : Set (Sym2 K)) := by
      rw [SimpleGraph.edgeSet_fromEdgeSet]
      ext e
      simp only [Set.mem_diff, Sym2.mem_diagSet, Finset.mem_coe]
      exact ⟨fun h => h.1, fun h => ⟨h, hno e h⟩⟩
    rw [hedge, Set.ncard_coe_finset, ht_card]
  · -- Every edge crosses the split, so a length-three closed walk is impossible.
    intro a w hlen
    have hbip : ∀ x y : K, (SimpleGraph.fromEdgeSet (↑t : Set (Sym2 K))).Adj x y →
        (if x ∈ A then true else false) ≠ (if y ∈ A then true else false) := by
      intro x y hxy
      rw [SimpleGraph.fromEdgeSet_adj] at hxy
      obtain ⟨hmem, -⟩ := hxy
      rw [Finset.mem_coe] at hmem
      have hcr := ht_sub hmem
      simp only [Finset.mem_image] at hcr
      obtain ⟨p, hp, hpe⟩ := hcr
      rw [Finset.mem_product] at hp
      rcases Sym2.eq_iff.mp hpe with ⟨h1, h2⟩ | ⟨h1, h2⟩
      · have hxA : x ∈ A := by rw [← h1]; exact hp.1
        have hyA : y ∉ A := by rw [← h2]; exact (Finset.mem_sdiff.mp hp.2).2
        rw [if_pos hxA, if_neg hyA]; decide
      · have hyA : y ∈ A := by rw [← h1]; exact hp.1
        have hxA : x ∉ A := by rw [← h2]; exact (Finset.mem_sdiff.mp hp.2).2
        rw [if_neg hxA, if_pos hyA]; decide
    have ha0 : w.getVert 0 = a := w.getVert_zero
    have ha3 : w.getVert 3 = a := by rw [← hlen]; exact w.getVert_length
    have adj01 : (SimpleGraph.fromEdgeSet (↑t : Set (Sym2 K))).Adj (w.getVert 0) (w.getVert 1) :=
      w.adj_getVert_succ (i := 0) (by omega)
    have adj12 : (SimpleGraph.fromEdgeSet (↑t : Set (Sym2 K))).Adj (w.getVert 1) (w.getVert 2) :=
      w.adj_getVert_succ (i := 1) (by omega)
    have adj23 : (SimpleGraph.fromEdgeSet (↑t : Set (Sym2 K))).Adj (w.getVert 2) (w.getVert 3) :=
      w.adj_getVert_succ (i := 2) (by omega)
    have c1 := hbip _ _ adj01
    have c2 := hbip _ _ adj12
    have c3 := hbip _ _ adj23
    rw [ha0] at c1
    rw [ha3] at c3
    exact (by decide : ∀ p q r : Bool, p ≠ q → q ≠ r → r ≠ p → False) _ _ _ c1 c2 c3
