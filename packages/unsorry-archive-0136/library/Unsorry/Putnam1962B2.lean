import Mathlib

/-- Goal `putnam-1962-b2`: there is a family of subsets of `ℕ+`, indexed by `ℝ`, that is
strictly increasing for the strict-subset order.  We build it by enumerating `ℚ` with `ℕ+`
through a chosen bijection `e : ℕ+ ≃ ℚ`, and sending each real `x` to the set of indices
`n` whose rational `e n` lies strictly below `x`.  Monotonicity is immediate; strictness uses
the existence of a rational strictly between any two reals. -/
theorem putnam_1962_b2 : ∃ f : ℝ → Set ℕ+, ∀ a b : ℝ, a < b → f a ⊂ f b := by
  let e : ℕ+ ≃ ℚ := Equiv.pnatEquivNat.trans (Denumerable.eqv ℚ).symm
  refine ⟨fun x => {n : ℕ+ | ((e n : ℚ) : ℝ) < x}, ?_⟩
  intro a b hab
  have hsub : {n : ℕ+ | ((e n : ℚ) : ℝ) < a} ⊆ {n : ℕ+ | ((e n : ℚ) : ℝ) < b} := by
    intro n hn
    exact lt_trans hn hab
  rw [Set.ssubset_iff_of_subset hsub]
  obtain ⟨q, haq, hqb⟩ := exists_rat_btwn hab
  refine ⟨e.symm q, ?_, ?_⟩
  · simp only [Set.mem_setOf_eq, Equiv.apply_symm_apply]
    exact hqb
  · simp only [Set.mem_setOf_eq, Equiv.apply_symm_apply, not_lt]
    exact le_of_lt haq
