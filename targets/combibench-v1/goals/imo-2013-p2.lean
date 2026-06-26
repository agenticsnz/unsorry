import Mathlib

structure Colombian_config : Type where
  (R B : Finset (ℝ × ℝ))
  (hR : R.card = 2013)
  (hB : B.card = 2014)
  (hC : R ∩ B = ∅)
  (h_no_collinear : ∀ p ∈ R ∪ B, ∀ q ∈ R ∪ B, ∀ r ∈ R ∪ B, p ≠ q → p ≠ r → q ≠ r →
    ¬ ∃ t : ℝ, t ≠ 0 ∧ t * (q.1 - p.1) = (r.1 - p.1) ∧ t * (q.2 - p.2) = (r.2 - p.2))
def Good_arrange (C : Colombian_config) (L : Finset (ℝ × ℝ × ℝ)) : Prop :=
  (∀ l ∈ L, l.1 ≠ 0 ∨ l.2.1 ≠ 0) ∧
  (∀ p ∈ C.R ∪ C.B, ∀ l ∈ L, l.1 * p.1 + l.2.1 * p.2 + l.2.2 ≠ 0) ∧
    ¬ (∃ q ∈ C.R, ∃ p ∈ C.B, ∀ l ∈ L,
      Real.sign (l.1 * p.1 + l.2.1 * p.2 + l.2.2) = Real.sign (l.1 * q.1 + l.2.1 * q.2 + l.2.2))

theorem imo_2013_p2 : IsLeast
    {k | ∀ C : Colombian_config, ∃ L : Finset (ℝ × ℝ × ℝ), L.card = k ∧ Good_arrange C L}
    ((2013) : ℕ ) := by
  sorry
