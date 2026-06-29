import Mathlib

open EuclideanGeometry Filter Topology Set
abbrev putnam_1972_a3_solution : Set (ℝ → ℝ) := {f | ∃ A B : ℝ, ∀ x ∈ Set.Icc 0 1, f x = A * x + B}

theorem putnam_1972_a3 (climit_exists : (ℕ → ℝ) → Prop)
    (supercontinuous : (ℝ → ℝ) → Prop)
    (hclimit_exists : ∀ x, climit_exists x ↔ ∃ C : ℝ, Tendsto (fun n => (∑ i ∈ Finset.range n, (x i))/(n : ℝ)) atTop (𝓝 C))
    (hsupercontinuous : ∀ f, supercontinuous f ↔ ∀ (x : ℕ → ℝ), (∀ i : ℕ, x i ∈ Icc 0 1) → climit_exists x → climit_exists (fun i => f (x i))) :
    {f | supercontinuous f} = putnam_1972_a3_solution := by
  sorry
