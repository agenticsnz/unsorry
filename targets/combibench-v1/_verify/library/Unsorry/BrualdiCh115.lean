import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Data.Fintype.EquivFin

/-!
# Brualdi, Chapter 11, Exercise 5

In a simple graph on `n ≥ 2` vertices, two distinct vertices share a degree.

Proof idea: every degree is `< n`, so the degree function is a map `Fin n → Fin n`.
If all degrees were distinct this map would be injective, hence surjective, so some
vertex `a` has degree `0` and some vertex `b` has degree `n - 1`. As `n ≥ 2` these are
different vertices. The neighbours of `b` lie in `univ.erase b`, which also has
`n - 1` elements, so `b` is adjacent to every other vertex, in particular to `a`.
This contradicts `a` having no neighbours.
-/

theorem brualdi_ch11_5 (n : ℕ) (h_n: n ≥ 2) (G : SimpleGraph (Fin n)) [DecidableRel G.Adj] :
    ∃ v1 v2, v1 ≠ v2 ∧ G.degree v1 = G.degree v2 := by
  by_contra hcon
  have hlt : ∀ v : Fin n, G.degree v < n := fun v => by
    simpa using G.degree_lt_card_verts v
  have hinj : Function.Injective (fun v : Fin n => (⟨G.degree v, hlt v⟩ : Fin n)) := by
    intro x y hxy
    by_contra hne
    exact hcon ⟨x, y, hne, congrArg Fin.val hxy⟩
  have hsurj := Finite.surjective_of_injective hinj
  obtain ⟨a, ha⟩ := hsurj ⟨0, by omega⟩
  obtain ⟨b, hb⟩ := hsurj ⟨n - 1, by omega⟩
  have ha' : G.degree a = 0 := congrArg Fin.val ha
  have hb' : G.degree b = n - 1 := congrArg Fin.val hb
  have hab : a ≠ b := by
    rintro rfl
    omega
  have hnb : G.neighborFinset b = Finset.univ.erase b := by
    apply Finset.eq_of_subset_of_card_le
    · intro x hx
      rw [SimpleGraph.mem_neighborFinset] at hx
      exact Finset.mem_erase.mpr ⟨hx.ne', Finset.mem_univ x⟩
    · rw [Finset.card_erase_of_mem (Finset.mem_univ b), Finset.card_univ, Fintype.card_fin,
        SimpleGraph.card_neighborFinset_eq_degree, hb']
  have hadj : G.Adj b a := by
    rw [← SimpleGraph.mem_neighborFinset, hnb]
    exact Finset.mem_erase.mpr ⟨hab, Finset.mem_univ a⟩
  have hempty : G.neighborFinset a = ∅ := Finset.card_eq_zero.mp ha'
  have hmem : b ∈ G.neighborFinset a := (G.mem_neighborFinset a b).mpr hadj.symm
  rw [hempty] at hmem
  exact Finset.notMem_empty b hmem
