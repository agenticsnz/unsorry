import Unsorry.Aime1983P9S1S1
import Unsorry.Aime1983P9S1S2

/-- For `0 < x < π`, the product `x * sin x` is positive: `sin` is positive on
the open interval, and a product of positives is positive. Assembled from the
kernel-verified sub-lemmas `aime_1983_p9_sin_pos` and `aime_1983_p9_mul_pos`. -/
theorem aime_1983_p9_xsin_pos (x : ℝ) (h₀ : 0 < x ∧ x < Real.pi) : 0 < x * Real.sin x :=
  aime_1983_p9_mul_pos x (Real.sin x) h₀.1 (aime_1983_p9_sin_pos x h₀.1 h₀.2)
