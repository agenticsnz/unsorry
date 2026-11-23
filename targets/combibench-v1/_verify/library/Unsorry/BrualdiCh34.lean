import Mathlib.Data.Finset.Card

/-!
Group the integers from 1 to 2n into n consecutive pairs. The pigeonhole
principle places two distinct elements of S in one pair, so they are consecutive.
-/

theorem brualdi_ch3_4 (n : ℕ) (S : Finset ℕ) (elem_range : ∀ s ∈ S, (1 ≤ s ∧ s ≤ 2 * n))
    (card : S.card = n + 1) : ∃ s ∈ S, ∃ s' ∈ S, s = s' + 1 := by
  have hmap : Set.MapsTo (fun s : ℕ => (s - 1) / 2) S (Finset.range n) := by
    intro s hs
    have hbounds := elem_range s hs
    apply Finset.mem_range.mpr
    change (s - 1) / 2 < n
    omega
  have hcard : (Finset.range n).card < S.card := by
    rw [Finset.card_range, card]
    omega
  obtain ⟨s, hs, t, ht, hne, heq⟩ :=
    Finset.exists_ne_map_eq_of_card_lt_of_maps_to hcard hmap
  change (s - 1) / 2 = (t - 1) / 2 at heq
  have hs_bounds := elem_range s hs
  have ht_bounds := elem_range t ht
  by_cases h : s = t + 1
  · exact ⟨s, hs, t, ht, h⟩
  · refine ⟨t, ht, s, hs, ?_⟩
    omega
