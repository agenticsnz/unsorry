import Unsorry.Aime1983P9S1
import Unsorry.Aime1983P9S3

/-!
AIME 1983 Problem 9: for `0 < x < π`, the expression
`(9 * (x ^ 2 * sin x ^ 2) + 4) / (x * sin x)` is at least `12`.

Assembled from the kernel-verified sub-lemmas: `aime_1983_p9_xsin_pos` gives
positivity of the denominator `x * sin x`, and `aime_1983_p9_amgm_div`
instantiated at `y = x * sin x` gives the AM–GM bound; rewriting
`x ^ 2 * sin x ^ 2` as `(x * sin x) ^ 2` reconciles the two statements.
-/

theorem aime_1983_p9 (x : ℝ) (h₀ : 0 < x ∧ x < Real.pi) :
    12 ≤ (9 * (x ^ 2 * Real.sin x ^ 2) + 4) / (x * Real.sin x) := by
  have h := aime_1983_p9_amgm_div (x * Real.sin x) (aime_1983_p9_xsin_pos x h₀)
  have hsq : x ^ 2 * Real.sin x ^ 2 = (x * Real.sin x) ^ 2 := by ring
  rw [hsq]
  exact h
