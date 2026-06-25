import Mathlib

open Set Function

/-- Goal `putnam-1964-a4`: a bounded integer sequence whose terms from index `4`
onward are a fixed function of the previous four terms is eventually periodic.

The recurrence pins each term (cast into `ℝ`) to a value determined by the four
preceding terms, so equal four-term windows force equal successors
(`key`). Boundedness confines the windows `(u n, u (n+1), u (n+2), u (n+3))` to a
finite set, so two distinct indices share a window (a pigeonhole step). Forward
determinism then propagates that coincidence indefinitely, yielding the period. -/
theorem putnam_1964_a4 (u : ℕ → ℤ)
    (boundedu : ∃ B T : ℤ, ∀ n : ℕ, B ≤ u n ∧ u n ≤ T)
    (hu : ∀ n ≥ 4, u n = ((u (n - 1) + u (n - 2) + u (n - 3) * u (n - 4)) : ℝ) /
        (u (n - 1) * u (n - 2) + u (n - 3) + u (n - 4)) ∧
        (u (n - 1) * u (n - 2) + u (n - 3) + u (n - 4)) ≠ 0) :
    (∃ N c : ℕ, c > 0 ∧ ∀ n ≥ N, u (n + c) = u n) := by
  -- Determinism: equal four-term windows have equal successors.
  have key : ∀ a b : ℕ, u a = u b → u (a + 1) = u (b + 1) → u (a + 2) = u (b + 2) →
      u (a + 3) = u (b + 3) → u (a + 4) = u (b + 4) := by
    intro a b h0 h1 h2 h3
    have ea := (hu (a + 4) (by omega)).1
    have eb := (hu (b + 4) (by omega)).1
    rw [show a + 4 - 1 = a + 3 from by omega, show a + 4 - 2 = a + 2 from by omega,
        show a + 4 - 3 = a + 1 from by omega, show a + 4 - 4 = a from by omega] at ea
    rw [show b + 4 - 1 = b + 3 from by omega, show b + 4 - 2 = b + 2 from by omega,
        show b + 4 - 3 = b + 1 from by omega, show b + 4 - 4 = b from by omega] at eb
    rw [h0, h1, h2, h3] at ea
    have hcast : (u (a + 4) : ℝ) = (u (b + 4) : ℝ) := by rw [ea, eb]
    exact_mod_cast hcast
  -- Reduce to: a strictly increasing pair of indices with the same window suffices.
  suffices H : ∀ p q : ℕ, p < q →
      (u p, u (p + 1), u (p + 2), u (p + 3)) = (u q, u (q + 1), u (q + 2), u (q + 3)) →
      (∃ N c : ℕ, c > 0 ∧ ∀ n ≥ N, u (n + c) = u n) by
    obtain ⟨B, T, hBT⟩ := boundedu
    set f : ℕ → ℤ × ℤ × ℤ × ℤ := fun n => (u n, u (n + 1), u (n + 2), u (n + 3)) with hf
    set t : Set (ℤ × ℤ × ℤ × ℤ) :=
      Set.Icc B T ×ˢ Set.Icc B T ×ˢ Set.Icc B T ×ˢ Set.Icc B T with ht
    have hfin : t.Finite :=
      (Set.finite_Icc B T).prod
        ((Set.finite_Icc B T).prod ((Set.finite_Icc B T).prod (Set.finite_Icc B T)))
    have hmaps : Set.MapsTo f Set.univ t := by
      intro n _
      simp only [hf, ht, Set.mem_prod, Set.mem_Icc]
      exact ⟨hBT n, hBT (n + 1), hBT (n + 2), hBT (n + 3)⟩
    obtain ⟨x, -, y, -, hne, hfeq⟩ :=
      (Set.infinite_univ (α := ℕ)).exists_ne_map_eq_of_mapsTo hmaps hfin
    rcases lt_or_gt_of_ne hne with h | h
    · exact H x y h hfeq
    · exact H y x h hfeq.symm
  intro p q hpq hfeq
  rw [Prod.mk.injEq, Prod.mk.injEq, Prod.mk.injEq] at hfeq
  obtain ⟨e0, e1, e2, e3⟩ := hfeq
  -- Forward determinism propagates the coincident window for every shift `j`.
  have per : ∀ j : ℕ, u (p + j) = u (q + j) ∧ u (p + j + 1) = u (q + j + 1) ∧
      u (p + j + 2) = u (q + j + 2) ∧ u (p + j + 3) = u (q + j + 3) := by
    intro j
    induction j with
    | zero => simp only [Nat.add_zero]; exact ⟨e0, e1, e2, e3⟩
    | succ k ih =>
      obtain ⟨a0, a1, a2, a3⟩ := ih
      have hk4 : u (p + k + 4) = u (q + k + 4) := key (p + k) (q + k) a0 a1 a2 a3
      refine ⟨?_, ?_, ?_, ?_⟩
      · rw [show p + (k + 1) = p + k + 1 from by omega,
            show q + (k + 1) = q + k + 1 from by omega]; exact a1
      · rw [show p + (k + 1) + 1 = p + k + 2 from by omega,
            show q + (k + 1) + 1 = q + k + 2 from by omega]; exact a2
      · rw [show p + (k + 1) + 2 = p + k + 3 from by omega,
            show q + (k + 1) + 2 = q + k + 3 from by omega]; exact a3
      · rw [show p + (k + 1) + 3 = p + k + 4 from by omega,
            show q + (k + 1) + 3 = q + k + 4 from by omega]; exact hk4
  refine ⟨p, q - p, by omega, ?_⟩
  intro n hn
  have hmain := (per (n - p)).1
  rw [show p + (n - p) = n from by omega, show q + (n - p) = n + (q - p) from by omega] at hmain
  exact hmain.symm
